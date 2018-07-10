module Authentication
  module AuthnK8s
    class AuthenticationError < RuntimeError; end
    class CSRVerificationError < RuntimeError; end
    class ClientCertVerificationError < RuntimeError; end
    class ClientCertExpiredError < RuntimeError; end
    class NotFoundError < RuntimeError; end
    
    class Authenticator
      def initialize(env:)
        @env = env
      end

      def inject_client_cert(params, request)
        # TODO: replace this hack
        @v4_controller = :login
        
        @params = params
        @request = request

        @service_id = params[:service_id]

        verify_enabled
        service_lookup
        host_lookup
        authorize_host
        load_ca
        find_pod
        find_container

        cert = @ca.issue pod_csr, [ "URI:#{spiffe_id}" ]
        install_signed_cert cert
      end
      
      def valid?(input)
        # TODO: replace this hack
        @v4_controller = :authenticate

        # some variables that need to be used in helper methods
        Rails.logger.debug("********* password")
        Rails.logger.debug(input.password)
        @client_cert = input.password
        @service_id = input.service_id
        @host_id_param = input.username
        
#        verify_enabled
        service_lookup
#        host_lookup
#        authorize_host
        load_ca
#        find_pod
#        find_container
        
        # Run through cert validations
        pod_certificate
        
        true
      end

      private

      ### TODO: The following section contains methods that were overridden in
      # two different controllers in the v4 implementation. This is a hacky way
      # of supporting both overrides in one class and should be replaced ASAP.
      
      def host_id_param
        if @v4_controller == :login
          host_id_param_login
        elsif @v4_controller == :authenticate
          host_id_param_authenticate
        end
      end

      def host_id_param_login
        if !@host_id_param
          cn_entry = get_subject_hash(pod_csr)["CN"]
          raise CSRVerificationError, 'CSR must contain CN' unless cn_entry
          
          @host_id_param = cn_entry.gsub('.', '/')
        end

        @host_id_param
      end

      def host_id_param_authenticate
        @host_id_param
      end

      def spiffe_id
        if @v4_controller == :login
          spiffe_id_login
        elsif @v4_controller == :authenticate
          spiffe_id_authenticate          
        end
      end

      def spiffe_id_login
        @spiffe_id ||= csr_spiffe_id(pod_csr)
      end

      def spiffe_id_authenticate
        @spiffe_id ||= cert_spiffe_id(pod_certificate)        
      end

      def pod_name
        if @v4_controller == :login
          pod_name_login
        elsif @v4_controller == :authenticate
          pod_name_authenticate
        end
      end

      def pod_name_login
        if !@pod_name
          raise CSRVerificationError, 'CSR must contain SPIFFE ID SAN' unless spiffe_id

          _, _, namespace, _, @pod_name = URI.parse(spiffe_id).path.split("/")
          raise CSRVerificationError, 'CSR SPIFFE ID SAN namespace must match conjur host id namespace' unless namespace == k8s_namespace
        end

        @pod_name
      end

      def pod_name_authenticate
        if !@pod_name
          raise ClientCertVerificationError, 'Client certificate must contain SPIFFE ID SAN' unless spiffe_id

          _, _, namespace, _, @pod_name = URI.parse(spiffe_id).path.split("/")
          raise ClientCertVerificationError, 'Client certificate SPIFFE ID SAN namespace must match conjur host id namespace' unless namespace == k8s_namespace
        end

        @pod_name
      end
      
      #----------------------------------------
      # authn-k8s LoginController helpers
      #----------------------------------------
      
      def install_signed_cert cert
        exec = KubectlExec.new @pod, container: k8s_container_name
        response = exec.copy "/etc/conjur/ssl/client.pem", cert.to_pem, "0644"
        
        if response[:error].present?
          raise AuthenticationError, response[:error].join
        end
      end

      def pod_csr
        if !@pod_csr
          @pod_csr = OpenSSL::X509::Request.new @request.body.read
          raise CSRVerificationError, 'CSR can not be verified' unless @pod_csr.verify @pod_csr.public_key
        end

        @pod_csr
      end

      # ssl stuff

      def csr_spiffe_id(csr)
        # https://stackoverflow.com/questions/46494429/how-to-get-an-attribute-from-opensslx509request
        attributes = csr.attributes
        raise CSRVerificationError, "CSR must contain workload SPIFFE ID subjectAltName" if not attributes

        seq = nil
        values = nil

        attributes.each do |a|
          if a.oid == 'extReq'
            seq = a.value
            break
          end
        end
        raise CSRVerificationError, "CSR must contain workload SPIFFE ID subjectAltName" if not seq

        seq.value.each do |v|
          v.each do |v|
            if v.value[0].value == 'subjectAltName'
              values = v.value[1].value
              break
            end
            break if values
          end
        end
        raise CSRVerificationError, "CSR must contain workload SPIFFE ID subjectAltName" if not values

        values = OpenSSL::ASN1.decode(values).value

        uris = begin
                 URI_from_asn1_seq(values)
               rescue StandardError => e
                 raise CSRVerificationError, e.message
               end

        raise CSRVerificationError, "CSR must contain exactly one URI SAN" unless (uris.count == 1)
        uris[0]
      end

      #----------------------------------------
      # authn-k8s AuthenticateController helpers
      #----------------------------------------

      def pod_certificate
        #client_cert = request.env['HTTP_X_SSL_CLIENT_CERTIFICATE']
        raise AuthenticationError, "No client certificate provided" unless @client_cert

        if !@pod_cert
          begin
            @pod_cert ||= OpenSSL::X509::Certificate.new(@client_cert)
          rescue OpenSSL::X509::CertificateError
          end

          # verify pod cert was signed by ca
          unless @pod_cert && @ca.verify(@pod_cert)
            raise ClientCertVerificationError, 'Client certificate cannot be verified by trusted certification authority'
          end

          # verify podname SAN matches calling pod ?

          # verify host_id matches CN
          cn_entry = get_subject_hash(@pod_cert)["CN"]

          Rails.logger.debug("******* CN TEST")
          Rails.logger.debug("CN: #{cn_entry.gsub('.', '/')}")
          Rails.logger.debug("host_id_param: #{host_id_param}")

          unless host_id_param.end_with?(cn_entry.gsub('.', '/'))
            raise ClientCertVerificationError, 'Client certificate CN must match host_id'
          end

          # verify pod cert is still valid
          if @pod_cert.not_after <= Time.now
            raise ClientCertExpiredError, 'Client certificate session expired'
          end
        end

        @pod_cert
      end

      # ssl stuff

      def cert_spiffe_id(cert)
        subject_alt_name = cert.extensions.find {|e| e.oid == "subjectAltName"}
        raise ClientCertVerificationError, "Client Certificate must contain pod SPIFFE ID subjectAltName" if not subject_alt_name

        # Parse the subject alternate name certificate extension as ASN1, first value should be the key
        asn_san = OpenSSL::ASN1.decode(subject_alt_name)
        raise "Expected ASN1 Subject Alternate Name extension key to be subjectAltName but was #{asn_san.value[0].value}" if asn_san.value[0].value != 'subjectAltName'

        # And the second value should be a nested ASN1 sequence
        values = OpenSSL::ASN1.decode(asn_san.value[1].value)

        uris =
          begin
            URI_from_asn1_seq(values)
          rescue StandardError => e
            raise ClientCertVerificationError, e.message
          end

        raise ClientCertVerificationError, "Client Certificate must contain exactly one URI SAN" unless (uris.count == 1)
        uris[0]
      end
      
      #----------------------------------------
      # authn-k8s ApplicationController helpers
      #----------------------------------------
      
      def verify_enabled
        conjur_authenticators = (@env['CONJUR_AUTHENTICATORS'] || '').split(',').map(&:strip)
        unless conjur_authenticators.include?("authn-k8s/#{service_id}")
          raise NotFoundError, "authn-k8s/#{service_id} not whitelisted in CONJUR_AUTHENTICATORS"
        end
      end

      def load_ca
        svc = AuthenticationService.new(@service.identifier)
        @ca ||= svc.load_ca
      end

      def find_container
        container =
          @pod.spec.containers.find { |c| c.name == k8s_container_name } ||
          @pod.spec.initContainers.find { |c| c.name == k8s_container_name }

        if container.nil?
          raise AuthenticationError, "Container #{k8s_container_name.inspect} not found in Pod #{@pod.metadata.name.inspect}"
        end

        container
      end

      def k8s_namespace
        host_id_tokens[-3]
      end

      def k8s_controller_name
        host_id_tokens[-2]
      end

      def k8s_object_name
        host_id_tokens[-1]
      end

      def k8s_container_name
        host.annotations.find { |a| a.values[:name] == 'kubernetes/authentication-container-name' }[:value] || 'authenticator'
      end

      def find_pod
        pod = K8sObjectLookup.find_pod_by_podname_in_namespace pod_name, k8s_namespace
        unless pod
          raise AuthenticationError, "No Pod found for podname #{pod_name} in namespace #{k8s_namespace.inspect}"
        end

        # TODO: enable in pure k8s
        # unless pod.status.podIP == request_ip
        #   raise AuthenticationError, "Pod IP does not match request IP #{request_ip.inspect}"
        # end

        if namespace_scoped?
          @pod = pod
        elsif permitted_scope?
          controller_object = K8sObjectLookup.find_object_by_name k8s_controller_name, k8s_object_name, k8s_namespace
          unless controller_object
            raise AuthenticationError, "Kubernetes #{k8s_controller_name} #{k8s_object_name.inspect} not found in namespace #{k8s_namespace.inspect}"
          end

          resolver = K8sResolver.for_controller(k8s_controller_name).new(controller_object, pod)
          # May raise K8sResolver#ValidationError
          resolver.validate_pod

          @pod = pod
        else
          raise AuthenticationError, "Resource type #{k8s_controller_name} identity scope is not supported in this version of authn-k8s"
          # find_pod_under_controller
        end
      end

      def namespace_scoped?
        k8s_controller_name == "*" && k8s_object_name == "*"
      end

      def permitted_scope?
        ["pod", "service_account", "deployment", "stateful_set", "deployment_config"].include? k8s_controller_name
      end

      def find_pod_under_controller
        pod = K8sObjectLookup.find_pod_by_request_ip_in_namespace request_ip, k8s_namespace
        unless pod
          raise AuthenticationError, "No Pod found for request IP #{request_ip.inspect} in namespace #{k8s_namespace.inspect}"
        end
        unless pod.metadata.namespace == k8s_namespace
          raise AuthenticationError, "Namespace of Pod #{pod.metadata.name.inspect} is #{pod.metadata.namespace.inspect}, not #{k8s_namespace.inspect}"
        end

        controller_object = K8sObjectLookup.find_object_by_name k8s_controller_name, k8s_object_name, k8s_namespace
        unless controller_object
          raise AuthenticationError, "Kubernetes #{k8s_controller_name} #{k8s_object_name.inspect} not found in namespace #{k8s_namespace.inspect}"
        end

        resolver = K8sResolver.for_controller(k8s_controller_name).new(controller_object, pod)
        resolver.validate_pod

        @pod = pod
      end

      def authorize_host
        unless host.role.allowed_to?("authenticate", @service)
          raise AuthenticationError, "#{host.role.id} does not have 'authenticate' privilege on #{@service.id}"
        end
      end

      def request_ip
        # In test & development, allow override of the request IP
        ip = if %w(test development).member?(Rails.env)
               params[:request_ip]
             end
        ip ||= Rack::Request.new(@request.env).ip
      end

      def service_id
#        @params[:service_id]
        @service_id
      end

      def service_lookup
        @service ||= Resource["#{@env['CONJUR_ACCOUNT']}:webservice:conjur/authn-k8s/#{service_id}"]
        raise NotFoundError, "Service #{service_id} not found" if @service.nil?
      end

      def host_lookup
        raise NotFoundError, "Host #{host.id} not found" unless host.exists?
      end

      def host
        @host ||= Resource[host_id]
      end

      def host_id
        [ host_id_prefix, host_id_param ].compact.join('/')
      end

      def host_id_prefix
        "#{@env['CONJUR_ACCOUNT']}:host:conjur/authn-k8s/#{service_id}/apps"
      end

      def host_id_tokens
        host_id_param.split('/').tap do |tokens|
          raise "Invalid host id; must end with k8s_namespace/k8s_controller_name/id" unless tokens.length >= 3
        end
      end

      protected

      # cert stuff

      def get_subject_hash(cert)
        cert.subject.to_a.each(&:pop).to_h
      end

      def URI_from_asn1_seq(values)
        result = []
        values.each do |v|
          case v.tag
          # uniformResourceIdentifier in GeneralName (RFC5280)
          when 6
            result << "#{v.value}"
          else
            raise StandardError, "Unknown tag in SAN, #{v.tag} -- Available: 2 (URI)\n"
          end
        end
        result
      end
    end
  end
end

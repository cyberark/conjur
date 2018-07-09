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
        @params = params
        @request = request
        
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
        # input has 5 attributes:
        #
        #     input.authenticator_name
        #     input.service_id
        #     input.account
        #     input.username
        #     input.password
        #
        # return true for valid credentials, false otherwise
      end

      private

      ### authn-k8s LoginController helpers

      def install_signed_cert cert
        exec = KubectlExec.new @pod, container: k8s_container_name
        response = exec.copy "/etc/conjur/ssl/client.pem", cert.to_pem, "0644"
        
        if response[:error].present?
          raise AuthenticationError, response[:error].join
        end
      end

      def host_id_param
        if !@host_id_param
          cn_entry = get_subject_hash(pod_csr)["CN"]
          raise CSRVerificationError, 'CSR must contain CN' unless cn_entry

          @host_id_param = cn_entry.gsub('.', '/')
        end

        @host_id_param
      end

      def spiffe_id
        @spiffe_id ||= csr_spiffe_id(pod_csr)
      end

      def pod_name
        if !@pod_name
          raise CSRVerificationError, 'CSR must contain SPIFFE ID SAN' unless spiffe_id

          _, _, namespace, _, @pod_name = URI.parse(spiffe_id).path.split("/")
          raise CSRVerificationError, 'CSR SPIFFE ID SAN namespace must match conjur host id namespace' unless namespace == k8s_namespace
        end

        @pod_name
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

      ### authn-k8s ApplicationController helpers
      
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
        host.resource.annotations['kubernetes/authentication-container-name'] || 'authenticator'
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
        raise AuthenticationError, "#{host.roleid} does not have 'authenticate' privilege on #{@service.resourceid}" unless @service.permitted?("authenticate")
      end

      def request_ip
        # In test & development, allow override of the request IP
        ip = if %w(test development).member?(Rails.env)
               params[:request_ip]
             end
        ip ||= Rack::Request.new(@request.env).ip
      end

      def service_id
        @params[:service_id]
      end

      def service_lookup
        @service ||= host_api_client.resource("#{@env['CONJUR_ACCOUNT']}:webservice:conjur/authn-k8s/#{service_id}")
        raise NotFoundError, "Service #{service_id} not found" unless @service.exists?
      end

      def host_lookup
        raise NotFoundError, "Host #{host.id} not found" unless host.exists?
      end

      def host
        @host ||= host_api_client.host(host_id)
      end

      def host_api_client
        @host_api_client ||= Conjur::API.new_from_token host_token
      end

      def host_token
        @host_token ||= Conjur::API.authenticate_local "host/#{host_id}"
      end

      def host_id_prefix
        "conjur/authn-k8s/#{service_id}/apps"
      end

      def host_id
        [ host_id_prefix, host_id_param ].compact.join('/')
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

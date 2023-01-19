require 'cgi'
require 'forwardable'
require 'command_class'

module Authentication
  module AuthnK8s

    Authenticator ||= CommandClass.new(
      dependencies: {validate_pod_request: ValidatePodRequest.new},
      inputs: [:authenticator_input]
    ) do
      extend Forwardable

      def_delegators :@authenticator_input, :service_id, :authenticator_name, :account, :username, :request

      def call
        validate_cert_exists
        validate_the_request
        validate_header_cert
      end

      private

      def validate_the_request
        @validate_pod_request.(pod_request: pod_request)
      end

      def validate_header_cert
        validate_cert_is_trusted
        validate_common_name_matches
        validate_cert_isnt_expired
        true
      end

      def validate_cert_exists
        raise Errors::Authentication::AuthnK8s::MissingClientCertificate unless header_cert_str
      end

      def validate_cert_is_trusted
        raise Errors::Authentication::AuthnK8s::UntrustedClientCertificate unless ca_can_verify_cert?
      end

      def validate_common_name_matches
        return if host_and_cert_cn_match?
        raise Errors::Authentication::AuthnK8s::CommonNameDoesntMatchHost.new(
          cert.common_name,
          host_common_name
        )
      end

      def validate_cert_isnt_expired
        raise Errors::Authentication::AuthnK8s::ClientCertificateExpired if cert_expired?
      end

      def cert
        @cert ||= ::Util::OpenSsl::X509::SmartCert.new(header_cert_str)
      end

      def ca_can_verify_cert?
        webservice_ca.verify(cert)
      end

      def host_and_cert_cn_match?
        cert.common_name == host_common_name
      end

      def cert_expired?
        cert.not_after <= Time.now
      end

      def header_cert_str
        str = request.env['HTTP_X_SSL_CLIENT_CERTIFICATE']
        str ? CGI.unescape(str) : nil
      end

      # username in this context is the host name
      def host_common_name
        resource_name = username
        CommonName.from_host_resource_name(resource_name).to_s
      end

      def webservice_ca
        # TODO: pull this into an object
        webservice_id = "#{account}:webservice:conjur/authn-k8s/#{service_id}"
        @webservice_ca ||= Repos::ConjurCA.ca(webservice_id)
      end

      # @return [SpiffeId] A SpiffeId value object
      def spiffe_id
        SpiffeId.new(cert.san_uri)
      end

      def pod_request
        PodRequest.new(
          service_id: service_id,
          k8s_host: K8sHost.from_cert(
            account: account,
            service_name: service_id,
            cert: header_cert_str
          ),
          spiffe_id: spiffe_id
        )
      end
    end

    class Authenticator
      # This delegates to all the work to the call method created automatically
      # by CommandClass
      #
      # This is needed because we need `valid?` to exist on the Authenticator
      # class, but that class contains only a metaprogramming generated
      # `call(authenticator_input:)` method.  The methods we define in the
      # block passed to `CommandClass` exist only on the private internal
      # `Call` objects created each time `call` is run.
      #
      def valid?(input)
        call(authenticator_input: input)
      end
    end
  end
end

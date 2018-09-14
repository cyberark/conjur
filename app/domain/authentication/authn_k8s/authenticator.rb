require 'cgi'
require 'forwardable'
require_relative 'errors'

module Authentication
  module AuthnK8s

    class Authenticator
      extend ::Util::CommandObject
      extend Forwardable

      dependencies env: ENV, validate_pod_request: ValidatePodRequest.new
      input :authenticator_input
      steps :validate_the_request, :validate_header_cert

      # TODO:
      # def_delegators @authenticator_input, :service_id, :authenticator_name,
      #                :account, :username, :request
      #
      def service_id
        authenticator_input.service_id
      end
      def authenticator_name
        authenticator_input.authenticator_name
      end
      def account
        authenticator_input.account
      end
      def username
        authenticator_input.username
      end
      def request
        authenticator_input.request
      end

      # This delegates to all the work to the call method created automatically
      # by the steps method above
      #
      def valid?(input)
        call(authenticator_input: input)
      end

      private

      def validate_the_request
        validate_pod_request.(pod_request)
      end

      def validate_header_cert
        validate_cert_exists
        validate_cert_is_trusted
        validate_common_name_matches
        validate_cert_isnt_expired
        true
      end

      def validate_cert_exists
        raise MissingClientCertificate unless header_cert_str
      end

      def validate_cert_is_trusted
        raise UntrustedClientCertificate unless ca_can_verify_cert?
      end

      def validate_common_name_matches
        raise CommonNameDoesntMatchHost unless host_and_cert_cn_match?
      end

      def validate_cert_isnt_expired
        raise ClientCertificateExpired if cert_expired?
      end

      def cert
        @cert ||= Util::OpenSsl::X509::SmartCert.new(header_cert_str)
      end

      def ca_can_verify_cert?
        webservice_ca.verify(cert)
      end

      def host_and_cert_cn_match?
        cert.common_name == host_name
      end

      def cert_expired?
        cert.not_after <= Time.now
      end

      def header_cert_str
        CGI.unescape(request.env['HTTP_X_SSL_CLIENT_CERTIFICATE'])
      end

      # username in this context is the host name
      def host_name
        CommonName.new(username).k8s_host_name
      end

      def webservice_ca
        @webservice_ca ||= Repos::ConjurCA.ca(service_id)
      end

      # @return [SpiffeId] A SpiffeId value object
      def spiffe_id
        SpiffeId.new(cert.san.sub(/^uri:/i, ''))
      end

      def pod_request
        puts("************")
        puts service_id
        puts account
        puts header_cert_str
        puts 'cert.san', cert.san
        puts 'spiffe_id', spiffe_id.inspect
        
        Rails.logger.debug("jonah #{header_cert_str}")
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

      #TODO: pull this code out of strategy into a separate object
      #      then use that object here and in Strategy.
      #
      # def validate_authenticator_enabled(service_name)
      #   authenticator_name = "authn-k8s/#{service_name}"
      #   valid = available_authenticators.include?(authenticator_name)
      #   raise AuthenticatorNotFound, authenticator_name unless valid
      # end

      # def available_authenticators
      #   (conjur_authenticators || '').split(',').map(&:strip)
      # end

      # def conjur_authenticators
      #   env['CONJUR_AUTHENTICATORS']
      # end

      # def conjur_account
      #   env['CONJUR_ACCOUNT']
      # end
    end
  end
end

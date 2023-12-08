module Authentication
  module AuthnK8s
    # AuthnK8s::ValidateStatus raises an exception if the Kubernetes
    # authenticator is not configured properly or with inadequate permissions.
    ValidateStatus = CommandClass.new(
      dependencies: {
        fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new(
          optional_variable_names: OPTIONAL_VARIABLE_NAMES
        )
      },
      inputs: %i[account service_id]
    ) do
      def call
        validate_configuration_values
      end

      protected

      def validate_configuration_values
        # Validate configuration values for k8s API access
        validate_k8s_service_account_token
        validate_k8s_ca_certificate
        validate_k8s_api_url

        # Validate configuration values for issuing authentication certificates
        validate_conjur_ca_certificate
        validate_conjur_ca_private_key
      end

      def validate_k8s_service_account_token
        k8s_service_account_token
      rescue JWT::DecodeError => e
        raise Errors::Authentication::AuthnK8s::InvalidServiceAccountToken,
              "Unable to decode JWT: #{e.message}"
      end

      def validate_k8s_ca_certificate
        # Ensure that none of the provided certificates have expired
        k8s_ca_certificate.each do |certificate|
          next unless certificate.not_after < Time.now

          raise(
            Errors::Authentication::AuthnK8s::InvalidApiCert,
            "Certificate has expired: #{certificate.subject}"
          )
        end
      rescue OpenSSL::X509::CertificateError => e
        raise(
          Errors::Authentication::AuthnK8s::InvalidApiCert,
          "Unable to read certificate: #{e.message}"
        )
      end

      def validate_k8s_api_url
        # URI#parse will gracefully handle an empty string, so we check for that
        # specifically here.
        return unless k8s_api_url.to_s == ''

        raise Errors::Authentication::AuthnK8s::InvalidApiUrl, k8s_api_url
      rescue URI::InvalidURIError
        raise Errors::Authentication::AuthnK8s::InvalidApiUrl, \
              authenticator_secrets['kubernetes/api-url']
      end

      def validate_conjur_ca_certificate
        conjur_ca_certificate
      rescue OpenSSL::X509::CertificateError => e
        raise Errors::Authentication::AuthnK8s::InvalidSigningCert,
              "Unable to read certificate: #{e.message}"
      end

      def validate_conjur_ca_private_key
        conjur_ca_private_key
      rescue OpenSSL::PKey::RSAError
        # We don't bubble up the internal error message to avoid leaking any
        # accidental information about the private key.
        raise Errors::Authentication::AuthnK8s::InvalidSigningKey,
              "Unable to read private key"
      end

      def authenticator_secrets
        @authenticator_secrets ||= @fetch_authenticator_secrets.call(
          service_id: @service_id,
          conjur_account: @account,
          authenticator_name: AUTHENTICATOR_NAME,
          required_variable_names: REQUIRED_VARIABLE_NAMES
        )
      end

      def k8s_service_account_token
        @k8s_service_account_token ||= \
          JWT.decode(k8s_service_account_token_input, nil, false)
      end

      def k8s_service_account_token_input
        # First check if we're using a service account token file (i.e when
        # we're running inside of Kubernetes)
        if File.exist?(SERVICEACCOUNT_TOKEN_PATH)
          return File.read(SERVICEACCOUNT_TOKEN_PATH)
        end

        # Because this variable is optional, it's possible for it to be nil and
        # we need to handle that case.
        authenticator_secrets['kubernetes/service-account-token'] || \
          raise(
            Errors::Conjur::RequiredResourceMissing,
            'kubernetes/service-account-token'
          )
      end

      def k8s_ca_certificate
        # This value may contain multiple certificates or certificate chains
        @k8s_ca_certificate ||= ::Conjur::CertUtils.parse_certs(
          k8s_ca_certificate_input
        )
      end

      def k8s_ca_certificate_input
        # First check if we're using a CA bundle file (i.e when we're running
        # inside of Kubernetes)
        if File.exist?(SERVICEACCOUNT_CA_PATH)
          return File.read(SERVICEACCOUNT_CA_PATH)
        end

        # Because this variable is optional, it's possible for it to be nil and
        # we need to handle that case.
        authenticator_secrets['kubernetes/ca-cert'] || \
          raise(Errors::Conjur::RequiredResourceMissing, 'kubernetes/ca-cert')
      end

      def k8s_api_url
        @k8s_api_url ||= URI.parse(k8s_api_url_input)
      end

      def k8s_api_url_input
        # The API URL may come from environment variables, if they're present
        host = ENV['KUBERNETES_SERVICE_HOST']
        port = ENV['KUBERNETES_SERVICE_PORT']

        if host.present? && port.present?
          return "https://#{host}:#{port}"
        end

        # Because this variable is optional, it's possible for it to be nil and
        # we need to handle that case.
        authenticator_secrets['kubernetes/api-url'] || \
          raise(Errors::Conjur::RequiredResourceMissing, 'kubernetes/api-url')
      end

      def conjur_ca_certificate
        @conjur_ca_certificate ||= \
          OpenSSL::X509::Certificate.new(
            authenticator_secrets['ca/cert']
          )
      end

      def conjur_ca_private_key
        @conjur_ca_private_key ||= \
          OpenSSL::PKey::RSA.new(
            authenticator_secrets['ca/key']
          )
      end
    end
  end
end

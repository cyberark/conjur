# frozen_string_literal: true

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

        # Validate configuration values for issuing authentication certificates.
        # ---
        # The certificate validation uses the private key, so we validate the
        # private key first.
        validate_conjur_ca_private_key
        validate_conjur_ca_certificate

        # Validate Kubernetes API access and authorization
        validate_k8s_api_access
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
        # Is the certificate expired?
        if conjur_ca_certificate.not_after < Time.now
          raise(
            Errors::Authentication::AuthnK8s::InvalidSigningCert,
            "Certificate has expired"
          )
        end

        # Does the certificate have the correct attributes for certificate signing?
        # basicConstraints should include CA:TRUE
        basic_constraints_present = conjur_ca_certificate
          .extensions
          .find do |ext|
            ext.oid == 'basicConstraints' && ext.value.include?('CA:TRUE')
          end
        unless basic_constraints_present
          raise(
            Errors::Authentication::AuthnK8s::InvalidSigningCert,
            "Certificate does not include basicConstraints attribute: CA:TRUE"
          )
        end

        # keyUsage should include Certificate Sign. This comes by setting the
        # value 'keyCertSign' when creating the certificate
        key_cert_sign_present = conjur_ca_certificate
          .extensions
          .find do |ext|
            ext.oid == 'keyUsage' && ext.value.include?('Certificate Sign')
          end
        unless key_cert_sign_present
          raise(
            Errors::Authentication::AuthnK8s::InvalidSigningCert,
            "Certificate does not include keyUsage attribute: 'Certificate Sign'"
          )
        end

        # Is the certificate valid with the private key?
        keys_match = conjur_ca_certificate.public_key.to_s == \
          conjur_ca_private_key.public_key.to_s
        unless keys_match
          raise(
            Errors::Authentication::AuthnK8s::InvalidSigningCert,
            "Certificate and private key do not match"
          )
        end
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

      def validate_k8s_api_access
        # To check our access token, we'll attempt to retrieve the base API
        # discovery URI. If we get a "401 Unauthorized response", then it
        # means the access token is invalid.
        #
        # If the response is "403 Forbidden", then it means the access token
        # is valid for authentication, but the service account is missing
        # authorization to perform API discovery. This requires the
        # 'system:discovery' role to be bound to the service account. See:
        # https://kubernetes.io/docs/reference/access-authn-authz/rbac/#discovery-roles
        #
        # Note, it is possible to configure Kubernetes such that API discovery
        # is publicly accessible, but that's not the default configuration and
        # isn't a configuration change we expect or support validating. In that
        # case, accessing the API discovery may not indicate the service account
        # token is valid.
        url = "#{k8s_api_url}/apis"

        RestClient.proxy = k8s_api_url.find_proxy

        headers = {
          Authorization: "Bearer #{k8s_service_account_token_input}",
          Accept: 'application/json'
        }
        RestClient::Request.execute(
          method: :get,
          url: url,
          headers: headers,
          ssl_cert_store: k8s_cert_store
        )
      rescue RestClient::Unauthorized => e
        raise(
          Errors::Authentication::AuthnK8s::InvalidServiceAccountToken,
          e.message
        )
      rescue RestClient::Forbidden => e
        raise(
          Errors::Authentication::AuthnK8s::InvalidServiceAccountToken,
          "Service account is unauthorized to perform API discovery: " \
            "#{e.message}. Ensure the 'system:discovery' role is bound to " \
            "service account"
        )
      end

      private

      def authenticator_secrets
        @authenticator_secrets ||= @fetch_authenticator_secrets.call(
          service_id: @service_id,
          conjur_account: @account,
          authenticator_name: AUTHENTICATOR_NAME,
          required_variable_names: REQUIRED_VARIABLE_NAMES
        )
      end

      def k8s_service_account_token
        # Ensure there are no invalid characters in the service account token
        #
        # This array must use double-quotes to ensure it's the special character
        # that we're checking for.
        invalid_chars = ["\n", "\r"]
        invalid_chars_present = invalid_chars.select do |char|
          k8s_service_account_token_input.include?(char)
        end

        if invalid_chars_present.any?
          raise(
            Errors::Authentication::AuthnK8s::InvalidServiceAccountToken,
            "Invalid characters in token: " \
              "#{invalid_chars_present.join(', ')}"
          )
        end

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
        @conjur_ca_certificate ||= begin
          certs = ::Conjur::CertUtils.parse_certs(
            authenticator_secrets['ca/cert']
          )

          # Should only be one
          if certs.length > 1
            raise(
              Errors::Authentication::AuthnK8s::InvalidSigningCert,
              "Value contains multiple certificates. " \
              "Only a single signing certificate allowed"
            )
          end

          certs.first
        end
      end

      def conjur_ca_private_key
        @conjur_ca_private_key ||= \
          OpenSSL::PKey::RSA.new(
            authenticator_secrets['ca/key']
          )
      end

      def k8s_cert_store
        @k8s_cert_store ||= OpenSSL::X509::Store.new.tap do |store|
          store.set_default_paths

          k8s_ca_certificate.each do |cert|
            store.add_cert(cert)
          end

          if ENV.key?('SSL_CERT_DIRECTORY')
            ::Conjur::CertUtils.load_certificates(
              store,
              File.join(ENV['SSL_CERT_DIRECTORY'], 'ca')
            )
          end
        end
      end
    end
  end
end

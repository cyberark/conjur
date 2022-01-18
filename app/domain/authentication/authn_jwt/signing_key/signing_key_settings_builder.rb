module Authentication
  module AuthnJwt
    module SigningKey

      NO_SIGNING_KEYS_SOURCE = "One of the following must be defined: #{JWKS_URI_RESOURCE_NAME}, #{PUBLIC_KEYS_RESOURCE_NAME}, or #{PROVIDER_URI_RESOURCE_NAME}".freeze
      ALL_SIGNING_KEYS_SOURCES = "#{JWKS_URI_RESOURCE_NAME}, #{PUBLIC_KEYS_RESOURCE_NAME}, and #{PROVIDER_URI_RESOURCE_NAME} cannot be defined simultaneously".freeze
      JWKS_PROVIDER_URI_SIGNING_PAIR = "#{JWKS_URI_RESOURCE_NAME} and #{PROVIDER_URI_RESOURCE_NAME} cannot be defined simultaneously".freeze
      JWKS_URI_PUBLIC_KEYS_PAIR = "#{JWKS_URI_RESOURCE_NAME} and #{PUBLIC_KEYS_RESOURCE_NAME} cannot be defined simultaneously".freeze
      PUBLIC_KEYS_PROVIDER_URI_PAIR = "#{PUBLIC_KEYS_RESOURCE_NAME} and #{PROVIDER_URI_RESOURCE_NAME} cannot be defined simultaneously".freeze
      CERT_STORE_ONLY_WITH_JWKS_URI = "#{CA_CERT_RESOURCE_NAME} can only be defined together with #{JWKS_URI_RESOURCE_NAME}".freeze
      PUBLIC_KEYS_HAVE_ISSUER = "#{ISSUER_RESOURCE_NAME} is mandatory when #{PUBLIC_KEYS_RESOURCE_NAME} is defined".freeze

      # fetches signing key settings, validates and builds SigningKeysSettings object
      SigningKeySettingsBuilder = CommandClass.new(
        dependencies: {
          signing_key_settings_class: Authentication::AuthnJwt::SigningKey::SigningKeySettings
        },
        inputs: %i[signing_key_parameters]
      ) do
        def call
          validate_signing_key_parameters
          signing_key_settings
        end

        private

        def validate_signing_key_parameters
          single_signing_key_source
          cert_store_only_with_jwks_uri
          public_keys_have_issuer
        end

        def single_signing_key_source
          check_no_signing_keys_source
          check_all_signing_keys_sources
          check_jwks_provider_uri_pair
          check_jwks_uri_public_keys_pair
          check_public_keys_provider_uri_pair
        end

        def check_no_signing_keys_source
          return unless !jwks_uri && !provider_uri && !public_keys

          raise Errors::Authentication::AuthnJwt::InvalidSigningKeySettings, NO_SIGNING_KEYS_SOURCE
        end

        def check_all_signing_keys_sources
          return unless jwks_uri && public_keys &&  provider_uri

          raise Errors::Authentication::AuthnJwt::InvalidSigningKeySettings, ALL_SIGNING_KEYS_SOURCES
        end

        def check_jwks_provider_uri_pair
          return unless jwks_uri && provider_uri

          raise Errors::Authentication::AuthnJwt::InvalidSigningKeySettings, JWKS_PROVIDER_URI_SIGNING_PAIR
        end

        def check_jwks_uri_public_keys_pair
          return unless jwks_uri && public_keys

          raise Errors::Authentication::AuthnJwt::InvalidSigningKeySettings, JWKS_URI_PUBLIC_KEYS_PAIR
        end

        def check_public_keys_provider_uri_pair
          return unless public_keys && provider_uri

          raise Errors::Authentication::AuthnJwt::InvalidSigningKeySettings, PUBLIC_KEYS_PROVIDER_URI_PAIR
        end

        def cert_store_only_with_jwks_uri
          return unless ca_cert && !jwks_uri

          raise Errors::Authentication::AuthnJwt::InvalidSigningKeySettings, CERT_STORE_ONLY_WITH_JWKS_URI
        end

        def public_keys_have_issuer
          return unless public_keys && !issuer

          raise Errors::Authentication::AuthnJwt::InvalidSigningKeySettings, PUBLIC_KEYS_HAVE_ISSUER
        end

        def signing_key_settings
          @signing_key_settings_class.new(
            uri: signing_key_settings_uri,
            type: signing_key_settings_type,
            cert_store: signing_key_settings_cert_store,
            signing_keys: public_keys
          )
        end

        def signing_key_settings_uri
          return jwks_uri if jwks_uri
          return provider_uri if provider_uri
        end

        def signing_key_settings_type
          return JWKS_URI_INTERFACE_NAME if jwks_uri
          return PROVIDER_URI_INTERFACE_NAME if provider_uri
          return PUBLIC_KEYS_INTERFACE_NAME if public_keys
        end

        def signing_key_settings_cert_store
          return unless ca_cert

          cert_store = OpenSSL::X509::Store.new
          Conjur::CertUtils.add_chained_cert(cert_store, ca_cert)
          cert_store
        end

        def jwks_uri
          @signing_key_parameters[JWKS_URI_RESOURCE_NAME]
        end

        def provider_uri
          @signing_key_parameters[PROVIDER_URI_RESOURCE_NAME]
        end

        def public_keys
          @signing_key_parameters[PUBLIC_KEYS_RESOURCE_NAME]
        end

        def ca_cert
          @signing_key_parameters[CA_CERT_RESOURCE_NAME]
        end

        def issuer
          @signing_key_parameters[ISSUER_RESOURCE_NAME]
        end
      end
    end
  end
end

require 'uri'

module Authentication
  module AuthnJwt
    module ValidateAndDecode
      # FetchIssuerValue command class is responsible to fetch the issuer secret value,
      # in order to validate it later against the JWT token claim
      FetchIssuerValue ||= CommandClass.new(
        dependencies: {
          resource_class: ::Resource,
          fetch_secrets: ::Conjur::FetchRequiredSecrets.new,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do
        extend(Forwardable)
        def_delegators(:@authentication_parameters, :service_id, :authenticator_name,
                       :account)

        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingIssuerConfigurationValue.new)
          fetch_issuer_value
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchedIssuerValueFromConfiguration.new)

          @issuer_value
        end

        private

        # fetch_issuer_value function is responsible to fetch the issuer secret value,
        # according to the following logic:
        # Fetch from `issuer` authenticator resource,
        # In case `issuer` authenticator resource not configured, then only 1 resource, `provider-uri` or `jwks-uri`,
        # should be configured.
        # So the priority is:
        # 1. issuer
        # 2. provider-uri or jwks-uri
        # In case the resource is configured but the not initialized with secret, throw an error
        def fetch_issuer_value
          if issuer_resource_exists?
            @logger.debug(LogMessages::Authentication::AuthnJwt::IssuerResourceNameConfiguration.new(resource_id(ISSUER_RESOURCE_NAME)))

            @issuer_value=issuer_secret_value
          else
            validate_issuer_configuration

            if provider_uri_resource_exists?
              @logger.debug(LogMessages::Authentication::AuthnJwt::IssuerResourceNameConfiguration.new(resource_id(PROVIDER_URI_RESOURCE_NAME)))

              @issuer_value=provider_uri_secret_value
            elsif jwks_uri_resource_exists?
              @logger.debug(LogMessages::Authentication::AuthnJwt::IssuerResourceNameConfiguration.new(resource_id(JWKS_URI_RESOURCE_NAME)))

              @issuer_value=fetch_issuer_from_jwks_uri_secret
            end
          end

          @logger.debug(LogMessages::Authentication::AuthnJwt::RetrievedIssuerValue.new(@issuer_value))
        end

        def issuer_resource_exists?
          !issuer_resource.nil?
        end

        def issuer_resource
          @issuer_resource ||= resource(ISSUER_RESOURCE_NAME)
        end

        def resource(resource_name)
          @resource_class[resource_id(resource_name)]
        end

        def resource_id(resource_name)
          "#{account}:variable:conjur/#{authenticator_name}/#{service_id}/#{resource_name}"
        end

        def issuer_secret_value
          @issuer_secret_value ||= issuer_secret[resource_id(ISSUER_RESOURCE_NAME)]
        end

        def issuer_secret
          @issuer_secret ||= @fetch_secrets.(resource_ids: [resource_id(ISSUER_RESOURCE_NAME)])
        end

        def validate_issuer_configuration
          if (provider_uri_resource_exists? && jwks_uri_resource_exists?) ||
              (!provider_uri_resource_exists? && !jwks_uri_resource_exists?)
            raise Errors::Authentication::AuthnJwt::InvalidIssuerConfiguration.new(
              ISSUER_RESOURCE_NAME,
              PROVIDER_URI_RESOURCE_NAME,
              JWKS_URI_RESOURCE_NAME
            )
          end
        end

        def provider_uri_resource_exists?
          !provider_uri_resource.nil?
        end

        def jwks_uri_resource_exists?
          !jwks_uri_resource.nil?
        end

        def provider_uri_resource
          @provider_uri_resource ||= resource(PROVIDER_URI_RESOURCE_NAME)
        end

        def jwks_uri_resource
          @jwks_uri_resource ||= resource(JWKS_URI_RESOURCE_NAME)
        end

        def provider_uri_secret_value
          @provider_uri_secret_value ||= provider_uri_secret[resource_id(PROVIDER_URI_RESOURCE_NAME)]
        end

        def provider_uri_secret
          @provider_uri_secret ||= @fetch_secrets.(resource_ids: [resource_id(PROVIDER_URI_RESOURCE_NAME)])
        end

        def fetch_issuer_from_jwks_uri_secret
          @logger.debug(LogMessages::Authentication::AuthnJwt::ParsingIssuerFromUri.new(jwks_uri_secret_value))

          begin
            @issuer_from_jwks_uri_secret ||= URI.parse(jwks_uri_secret_value).hostname
          rescue => e
            raise Errors::Authentication::AuthnJwt::InvalidUriFormat.new(
              jwks_uri_secret_value,
              e.inspect
            )
          end

          if @issuer_from_jwks_uri_secret.blank?
            raise Errors::Authentication::AuthnJwt::FailedToParseHostnameFromUri, jwks_uri_secret_value
          end

          @issuer_from_jwks_uri_secret
        end

        def jwks_uri_secret_value
          @jwks_uri_secret_value ||=jwks_uri_secret[resource_id(JWKS_URI_RESOURCE_NAME)]
        end

        def jwks_uri_secret
          @jwks_uri_secret ||= @fetch_secrets.(resource_ids: [resource_id(JWKS_URI_RESOURCE_NAME)])
        end
      end
    end
  end
end

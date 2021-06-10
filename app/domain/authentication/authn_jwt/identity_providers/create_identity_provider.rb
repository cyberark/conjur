require 'command_class'

module Authentication
  module AuthnJwt
    module IdentityProviders
      # Factory for jwt identity providers.
      # If Identity variable is configured factory return the decoded_token_provider
      # If the Identity variable is not configured and there is account field in url factory returns url provider
      # If the above conditions are not met exception is raised
      CreateIdentityProvider = CommandClass.new(
        dependencies: {
          identity_from_url_provider_class: Authentication::AuthnJwt::IdentityProviders::IdentityFromUrlProvider,
          identity_from_decoded_token_class: Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do
        def call
          create_identity_provider
        end

        private

        def identity_from_decoded_token_provider
          @identity_from_decoded_token_provider ||= @identity_from_decoded_token_class.new(@authentication_parameters)
        end

        def identity_from_url_provider
          @identity_from_url_provider ||= @identity_from_url_provider_class.new(@authentication_parameters)
        end

        def create_identity_provider
          @logger.debug(LogMessages::Authentication::AuthnJwt::SelectingIdentityProviderInterface.new)

          validate_identity_configuration
          if identity_from_decoded_token_provider.identity_available?
            @logger.info(
              LogMessages::Authentication::AuthnJwt::SelectedIdentityProviderInterface.new(
                TOKEN_IDENTITY_PROVIDER_INTERFACE_NAME
              )
            )
            identity_from_decoded_token_provider
          elsif identity_from_url_provider.identity_available?
            @logger.info(
              LogMessages::Authentication::AuthnJwt::SelectedIdentityProviderInterface.new(
                URL_IDENTITY_PROVIDER_INTERFACE_NAME
              )
            )
            identity_from_url_provider
          end
        end

        def validate_identity_configuration
          if (identity_from_decoded_token_provider.identity_available? && identity_from_url_provider.identity_available?) ||
              (!identity_from_decoded_token_provider.identity_available? && !identity_from_url_provider.identity_available?)
            raise Errors::Authentication::AuthnJwt::IdentityMisconfigured
          end
        end
      end
    end
  end
end

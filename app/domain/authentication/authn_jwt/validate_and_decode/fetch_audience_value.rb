require 'command_class'

module Authentication
  module AuthnJwt
    module ValidateAndDecode
      # Fetch and validate the audience from the JWT authenticator policy
      FetchAudienceValue = CommandClass.new(
        dependencies: {
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
          logger: Rails.logger
        },
        inputs: %i[authenticator_input]
      ) do
        extend(Forwardable)
        def_delegators(:@authenticator_input, :service_id, :authenticator_name, :account)

        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingAudienceValue.new)

          return empty_audience_value unless audience_resource_exists?

          fetch_audience_secret_value
          validate_audience_secret_has_value

          @logger.info(LogMessages::Authentication::AuthnJwt::FetchedAudienceValue.new(audience_secret_value))

          audience_secret_value
        end

        private

        def audience_resource_exists?
          return @audience_resource_exists if defined?(@audience_resource_exists)

          @audience_resource_exists ||= @check_authenticator_secret_exists.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            var_name: AUDIENCE_RESOURCE_NAME
          )
        end

        def empty_audience_value
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingAudienceValue.new)
          ''
        end

        def fetch_audience_secret_value
          audience_secret_value
        end

        def audience_secret_value
          @audience_secret_value ||= @fetch_authenticator_secrets.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            required_variable_names: [AUDIENCE_RESOURCE_NAME]
          )[AUDIENCE_RESOURCE_NAME]
        end

        def validate_audience_secret_has_value
          raise Errors::Authentication::AuthnJwt::AudienceValueIsEmpty if audience_secret_value.blank?
        end
      end
    end
  end
end

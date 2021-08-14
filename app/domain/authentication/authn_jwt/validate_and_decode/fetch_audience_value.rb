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
        inputs: %i[authentication_parameters]
      ) do

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
          return @audience_resource_exists unless @audience_resource_exists.nil?

          @audience_resource_exists ||= @check_authenticator_secret_exists.call(
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
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
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
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

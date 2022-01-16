module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for fetching values of all variables related
      # to signing key settings area
      FetchSigningKeyParametersFromVariables ||= CommandClass.new(
        dependencies: {
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new
        },
        inputs: %i[authenticator_input]
      ) do
        extend(Forwardable)
        def_delegators(:@authenticator_input, :account, :authenticator_name, :service_id)

        def call
          fetch_variables_values
          variables_values
        end

        private

        def fetch_variables_values
          SIGNING_KEY_RESOURCES_NAMES.each do |name|
            variables_values[name] = secret_value(secret_name: name)
          end
        end

        def variables_values
          @variables_values ||= {}
        end

        def secret_value(secret_name:)
          return nil unless secret_exists?(secret_name: secret_name)

          @fetch_authenticator_secrets.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            required_variable_names: [secret_name]
          )[secret_name]
        end

        def secret_exists?(secret_name:)
          @check_authenticator_secret_exists.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            var_name: secret_name
          )
        end
      end
    end
  end
end

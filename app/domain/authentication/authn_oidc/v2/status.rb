module Authentication
  module AuthnOidc
    module V2
      class Status
        def initialize(
          available_authenticators:,
          namespace_selector: Authentication::Util::NamespaceSelector,
          authenticator_repository: DB::Repository::AuthenticatorRepository,
          oidc_client: Authentication::AuthnOidc::V2::Client,
          variable_repository: DB::Repository::VariablesRepository.new
        )
          @available_authenticators = available_authenticators
          @namespace_selector = namespace_selector
          @authenticator_repository = authenticator_repository
          @oidc_client = oidc_client
          @variable_repository = variable_repository
        end

        def call(account:, authenticator_type:, service_id:)
          authenticator_enabled?(
            authenticator_name: "#{authenticator_type}/#{service_id}"
          )

          authenticator = load_authenticator(
            account: account,
            authenticator_type: authenticator_type,
            service_id: service_id
          )

          # Verify authenticator loads (all variables are set)
          if authenticator.blank?
            # If not, it's likely variable are missing
            check_for_missing_variables(account: account, authenticator_type: authenticator_type, service_id: service_id)
          end

          # Verify OIDC endpoint is available
          verify_connection(authenticator: authenticator)
        end

        # The following will raise an exception if endpoints are unavailable
        def verify_connection(authenticator:)
          @oidc_client.new(authenticator: authenticator).oidc_client
        end

        def authenticator_enabled?(authenticator_name:)
          return if @available_authenticators.include?(authenticator_name)

          raise Errors::Authentication::Security::AuthenticatorNotWhitelisted, authenticator_name
        end

        def check_for_missing_variables(account:, authenticator_type:, service_id:)
          data_object = authenticator_data_object(
            authenticator_type: authenticator_type
          )

          variables = @variable_repository.find_by_id_path(account: account, path: "conjur/#{authenticator_type}/#{service_id}")

          data_object.const_get(:REQUIRED_VARIABLES).each do |variable|
            full_variable_id = "#{account}:variable:conjur/#{authenticator_type}/#{service_id}/#{variable.to_s.dasherize}"

            unless variables.key?(full_variable_id)
              raise Errors::Conjur::RequiredResourceMissing, full_variable_id
            end

            unless variables[full_variable_id].present?
              raise Errors::Conjur::RequiredSecretMissing, full_variable_id
            end
          end
        end

        private

        def load_authenticator(account:, authenticator_type:, service_id:)
          data_object = authenticator_data_object(
            authenticator_type: authenticator_type
          )

          @authenticator_repository.new(
            data_object: data_object
          ).find(
            type: authenticator_type,
            account: account,
            service_id: service_id
          )
        end

        def authenticator_data_object(authenticator_type:)
          namespace = @namespace_selector.select(
            authenticator_type: authenticator_type
          )
          "#{namespace}::DataObjects::Authenticator".constantize
        end
      end
    end
  end
end

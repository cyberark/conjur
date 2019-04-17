require 'command_class'
require 'conjur/fetch_required_secrets'

module Authentication
  module AuthnOidc
    module Util
      # Errors from FetchRequiredSecrets
      RequiredResourceMissing = ::Conjur::RequiredResourceMissing
      RequiredSecretMissing = ::Conjur::RequiredSecretMissing

      class FetchOidcSecrets
        extend CommandClass::Include

        command_class(
          dependencies: {
            fetch_secrets: ::Conjur::FetchRequiredSecrets.new
          },
          inputs: %i(conjur_account service_id required_variable_names)
        ) do

          def call
            secrets = {}

            required_secrets = @fetch_secrets.(resource_ids: required_resource_ids)

            @required_variable_names.each do |variable_name|
              full_variable_name = full_variable_name(variable_name)
              secrets[variable_name] = required_secrets[full_variable_name]
            end

            secrets
          end

          private

          def required_resource_ids
            @required_variable_names.map { |var_name| full_variable_name(var_name) }
          end

          def full_variable_name(var_name)
            "#{@conjur_account}:variable:conjur/authn-oidc/#{@service_id}/#{var_name}"
          end
        end
      end
    end
  end
end
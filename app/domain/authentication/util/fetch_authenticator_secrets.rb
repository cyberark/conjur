require 'command_class'
require 'conjur/fetch_required_secrets'

module Authentication
  module Util

    FetchAuthenticatorSecrets = CommandClass.new(
      dependencies: {
        fetch_required_secrets: ::Conjur::FetchRequiredSecrets.new,
        fetch_optional_secrets: ::Conjur::FetchOptionalSecrets.new,
        optional_variable_names: []
      },
      inputs: %i[conjur_account authenticator_name service_id required_variable_names]
    ) do
      def call
        secret_map_for(@required_variable_names, required_secrets).merge(secret_map_for(@optional_variable_names, optional_secrets))
      end

      private

      def required_secrets
        @required_secrets ||= @fetch_required_secrets.(resource_ids: resource_ids_for(@required_variable_names))
      end

      def optional_secrets
        @optional_secrets ||= @fetch_optional_secrets.(resource_ids: resource_ids_for(@optional_variable_names))
      end

      def secret_map_for(variable_names, secret_values)
        variable_names.each_with_object({}) do |variable_name, secrets|
          full_variable_name     = full_variable_name(variable_name)
          secrets[variable_name] = secret_values[full_variable_name]
        end
      end

      def resource_ids_for(variable_names)
        variable_names.map { |var_name| full_variable_name(var_name) }
      end

      def full_variable_name(var_name)
        "#{@conjur_account}:variable:conjur/#{@authenticator_name}/#{@service_id}/#{var_name}"
      end
    end
  end
end

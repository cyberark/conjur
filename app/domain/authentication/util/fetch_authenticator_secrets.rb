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
        secret_map_for(required_secrets).merge(secret_map_for(optional_secrets))
      end

      private

      def required_secrets
        @required_secrets ||= @fetch_required_secrets.(resource_ids: resource_ids_for(@required_variable_names))
      end

      def optional_secrets
        @optional_secrets ||= @fetch_optional_secrets.(resource_ids: resource_ids_for(@optional_variable_names))
      end

      def secret_map_for(secret_values)
        secret_values.each_with_object({}) do |(full_name, value), secrets|
          short_name = full_name.to_s.split('/')[-1]
          secrets[short_name] = value
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

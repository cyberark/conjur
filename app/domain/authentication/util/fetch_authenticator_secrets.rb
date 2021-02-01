require 'command_class'
require 'conjur/fetch_required_secrets'

module Authentication
  module Util

    FetchAuthenticatorSecrets = CommandClass.new(
      dependencies: {
        fetch_secrets: ::Conjur::FetchRequiredSecrets.new
      },
      inputs:       %i[conjur_account authenticator_name service_id required_variable_names]
    ) do

      def call
        @required_variable_names.each_with_object({}) do |variable_name, secrets|
          full_variable_name     = full_variable_name(variable_name)
          secrets[variable_name] = required_secrets[full_variable_name]
        end
      end

      private

      def required_secrets
        @required_secrets ||= @fetch_secrets.(resource_ids: required_resource_ids)
      end

      def required_resource_ids
        @required_variable_names.map { |var_name| full_variable_name(var_name) }
      end

      def full_variable_name(var_name)
        "#{@conjur_account}:variable:conjur/#{@authenticator_name}/#{@service_id}/#{var_name}"
      end
    end
  end
end

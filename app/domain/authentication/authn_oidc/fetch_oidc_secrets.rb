require 'command_class'
require 'conjur/fetch_required_secrets'

module Authentication
  module AuthnOidc

    # TODO: (later version) Fix CommandClass so we can add errors directly
    # inside of it
    #
    # TODO: list any OIDC or other errors here.  The errors are part of the
    # API.
    #
    # Errors from FetchRequiredSecrets
    #
    RequiredResourceMissing = ::Conjur::RequiredResourceMissing
    RequiredSecretMissing   = ::Conjur::RequiredSecretMissing

    FetchOidcSecrets = CommandClass.new(
      dependencies: {
        fetch_secrets: ::Conjur::FetchRequiredSecrets.new
      },
      inputs:       %i(conjur_account service_id required_variable_names)
    ) do

      def call
        oidc_secrets
      end

      private

      def required_secrets
        @required_secrets ||= @fetch_secrets.(resource_ids: required_resource_ids)
      end

      def required_resource_ids
        @required_variable_names.map { |var_name| variable_id(var_name) }
      end

      def variable_id(var_name)
        "#{@conjur_account}:variable:conjur/authn-oidc/#{@service_id}/#{var_name}"
      end

      def secret_value(var_name)
        required_secrets[variable_id(var_name)]
      end

      def oidc_secrets
        secrets = {}

        @required_variable_names.each do |variable_name|
          secrets[variable_name] = secret_value(variable_name)
        end

        secrets
      end
    end
  end
end

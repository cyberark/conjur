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
    RequiredSecretMissing = ::Conjur::RequiredSecretMissing

    GetOidcClientConfiguration = CommandClass.new(
      dependencies: {
        fetch_secrets: ::Conjur::FetchRequiredSecrets.new
      },
      inputs: %i(redirect_uri service_id conjur_account)
    ) do

      def call
        oidc_client_configuration
      end

      private

      def required_secrets
        @required_secrets ||= @fetch_secrets.(resource_ids: required_resource_ids)
      end

      def required_resource_ids
        required_variable_names.map { |var_name| variable_id(var_name) }
      end

      def required_variable_names
        %w(client-id client-secret provider-uri)
      end

      # TODO: for next version: push this logic into a reusable value object
      #
      # NOTE: technically this should be memoized by argument (through memoist
      # gem, eg) but the calc is so simple it doesn't matter.
      def variable_id(var_name)
        "#{@conjur_account}:variable:conjur/authn-oidc/#{@service_id}/#{var_name}"
      end

      def client_id
        secret_value('client-id')
      end

      def client_secret
        secret_value('client-secret')
      end

      def provider_uri
        secret_value('provider-uri')
      end

      def secret_value(var_name)
        required_secrets[variable_id(var_name)]
      end

      def oidc_client_configuration
        ClientConfiguration.new(
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: @redirect_uri,
          provider_uri: provider_uri
        )
      end
    end
  end
end

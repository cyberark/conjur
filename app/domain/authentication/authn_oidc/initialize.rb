# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnOidc

    class OidcAuthenticatorData
      attr_reader :provider_uri, :id_token_user, :json_data

      def initialize(raw_post)
        @json_data = JSON.parse(raw_post)

        @provider_uri = @json_data['provider-uri']
        @id_token_user = @json_data['id-token-user-property']
      end
      
      def auth_name
        "authn-oidc"
      end

      # TODO Validation: Need to validate json_data contents and each individual variable
    end

  end
end

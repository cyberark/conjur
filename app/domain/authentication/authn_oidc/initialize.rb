# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnOidc

    # Secrets used when persisting a OIDC authenticator
    class OidcAuthenticatorData
      include ActiveModel::Validations
      attr_reader :provider_uri, :id_token_user, :json_data

      def initialize(json_data)
        @json_data = json_data

        @provider_uri = @json_data['provider-uri']
        @id_token_user = @json_data['id-token-user-property']
      end
      
      def auth_name
        "authn-oidc"
      end

      def json_parameters
        [ 'provider-uri', 'id-token-user-property' ]
      end

      validates(
        :json_data,
        presence: true,
        json: true
      )

      validates(
        :provider_uri,
        presence: true,
        url: true
      )

      validates(
        :id_token_user,
        presence: true
      )
    end

  end
end

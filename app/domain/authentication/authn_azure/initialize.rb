# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnAzure

    # Secrets used when persisting a Azure authenticator
    class AzureAuthenticatorData
      include ActiveModel::Validations
      attr_reader :provider_uri, :json_data

      def initialize(json_data)
        @json_data = json_data

        @provider_uri = @json_data['provider-uri']
      end
      
      def auth_name
        "authn-azure"
      end

      def json_parameters
        [ 'provider-uri' ]
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
    end

  end
end

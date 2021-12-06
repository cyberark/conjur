# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnAzure

    class AzureAuthenticatorData
      attr_reader :provider_uri, :json_data

      def initialize(raw_post)
        @json_data = JSON.parse(raw_post)

        @provider_uri = @json_data['provider_uri']
      end
      
      def auth_name
        "authn-azure"
      end

      # TODO Validation: Need to validate json_data contents and each individual variable
    end

  end
end

# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnGcp

    # Secrets used when persisting a GCP authenticator
    class GcpAuthenticatorData
      include ActiveModel::Validations
      attr_reader :json_data

      def initialize(json_data)
        @json_data = json_data
      end
      
      def auth_name
        "authn-gcp"
      end

      def json_parameters
        [  ]
      end

      validates(
        :json_data,
        json: true
      )
    end

  end
end

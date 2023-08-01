# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnIam

    # Secrets used when persisting a IAM authenticator
    class IamAuthenticatorData
      include ActiveModel::Validations
      attr_reader :json_data

      def initialize(json_data)
        @json_data = json_data
      end
      
      def auth_name
        "authn-iam"
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

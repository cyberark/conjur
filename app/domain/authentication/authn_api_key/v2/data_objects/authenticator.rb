# frozen_string_literal: true

module Authentication
  module AuthnApiKey
    module V2
      module DataObjects

        # This DataObject encapsulates the data required for an Authn-IAM
        # authenticator.
        #
        class Authenticator < Authentication::Base::DataObject

          REQUIRES_ROLE_ANNOTIONS = false

          attr_reader(:account)

          # Authn API Key has no variables.
          # Service ID is ignored as
          #
          # rubocop:disable Lint/MissingSuper
          def initialize(account:)
            @account = account
          end
          # rubocop:enable Lint/MissingSuper

          # Override type as this class's name does not match the expected
          # value of 'authn'. This is because API key is the default mechanism
          # for logging into Conjur.
          def type
            'authn'
          end
        end
      end
    end
  end
end

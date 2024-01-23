# frozen_string_literal: true

module Authentication
  module AuthnApiKey
    module V2
      module DataObjects

        # This DataObject encapsulates the data required for an Authn-API-Key
        # authenticator.
        class Authenticator < Authentication::Base::DataObject

          # Authn API Key has no variables.
          #
          # Service ID is ignored as API key authentication is enabled for
          # all accounts.
          def initialize(account:)
            super(account: account)
          end

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

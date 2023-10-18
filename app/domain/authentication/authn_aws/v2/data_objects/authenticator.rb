# frozen_string_literal: true

module Authentication
  module AuthnAws
    module V2
      module DataObjects

        # This DataObject encapsulates the data required for an Authn-IAM
        # authenticator.
        #
        class Authenticator < Authentication::Base::DataObject

          REQUIRES_ROLE_ANNOTIONS = false

          attr_reader(
            :account,
            :service_id
          )

          # Authn AWS has no variables.
          # Service ID is optional for backward compatability (as no variables are required)
          #
          # rubocop:disable Lint/MissingSuper
          def initialize(account:, service_id: nil)
            @account = account
            @service_id = service_id
          end
          # rubocop:enable Lint/MissingSuper
        end
      end
    end
  end
end

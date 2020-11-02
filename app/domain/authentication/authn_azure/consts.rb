# frozen_string_literal: true

module Authentication
  module AuthnAzure
    module Restrictions

      SUBSCRIPTION_ID = "subscription-id"
      RESOURCE_GROUP = "resource-group"
      USER_ASSIGNED_IDENTITY = "user-assigned-identity"
      SYSTEM_ASSIGNED_IDENTITY = "system-assigned-identity"

      REQUIRED = [SUBSCRIPTION_ID, RESOURCE_GROUP].freeze
      IDENTITY_EXCLUSIVE = [USER_ASSIGNED_IDENTITY, SYSTEM_ASSIGNED_IDENTITY].freeze
      PERMITTED = REQUIRED + IDENTITY_EXCLUSIVE

      CONSTRAINTS = Constraints::MultipleConstraint.new(
        Constraints::RequiredConstraint.new(required: REQUIRED),
        Constraints::PermittedConstraint.new(permitted: PERMITTED),
        Constraints::ExclusiveConstraint.new(exclusive: IDENTITY_EXCLUSIVE)
      )

    end
  end
end

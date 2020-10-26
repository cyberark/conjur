# frozen_string_literal: true

module Authentication
  module AuthnGcp

    PROVIDER_URI = "https://accounts.google.com"

    module Restrictions

      PROJECT_ID = "project-id"
      INSTANCE_NAME = "instance-name"
      SERVICE_ACCOUNT_ID = "service-account-id"
      SERVICE_ACCOUNT_EMAIL = "service-account-email"

      PERMITTED = [PROJECT_ID, INSTANCE_NAME, SERVICE_ACCOUNT_ID, SERVICE_ACCOUNT_EMAIL]

      CONSTRAINTS = Constraints::MultipleConstraint.new(
        Constraints::AnyConstraint.new(any_of: PERMITTED),
        Constraints::PermittedConstraint.new(permitted: PERMITTED)
      )

    end

  end
end

# frozen_string_literal: true

module Authentication
  module AuthnGcp

    PROVIDER_URI = "https://accounts.google.com"

    module Restrictions

      PROJECT_ID = "project-id"
      INSTANCE_NAME = "instance-name"
      SERVICE_ACCOUNT_ID = "service-account-id"
      SERVICE_ACCOUNT_EMAIL = "service-account-email"

      ANY = [PROJECT_ID, SERVICE_ACCOUNT_ID, SERVICE_ACCOUNT_EMAIL].freeze
      OPTIONAL = [INSTANCE_NAME].freeze
      PERMITTED = ANY + OPTIONAL

      CONSTRAINTS = Constraints::MultipleConstraint.new(
        Constraints::AnyConstraint.new(any: ANY),
        Constraints::PermittedConstraint.new(permitted: PERMITTED)
      )

    end

  end
end

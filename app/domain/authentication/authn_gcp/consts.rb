# frozen_string_literal: true

module Authentication
  module AuthnGcp

    PROVIDER_URI = "https://accounts.google.com"
    PROJECT_ID_RESTRICTION_NAME = "project-id"
    INSTANCE_NAME_RESTRICTION_NAME = "instance-name"
    SERVICE_ACCOUNT_ID_RESTRICTION_NAME = "service-account-id"
    SERVICE_ACCOUNT_EMAIL_RESTRICTION_NAME = "service-account-email"
    PERMITTED_CONSTRAINTS = %w(instance-name project-id service-account-id service-account-email)
    AUTHN_PREFIX = "authn-gcp/"

  end
end

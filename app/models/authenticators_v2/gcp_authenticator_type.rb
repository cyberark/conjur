# frozen_string_literal: true

module AuthenticatorsV2
  class GcpAuthenticatorType < AuthenticatorBaseType
    GCP_DEFAULT_NAME = 'default'

    def id
      # Return the conjur/authn-gcp branch because GCP does not include a service ID
      branch
    end

    def authenticator_name
      GCP_DEFAULT_NAME
    end
  end
end

# frozen_string_literal: true

require_relative './authenticator_base_type'

module AuthenticatorsV2
  class GcpAuthenticatorType < AuthenticatorBaseType
    GCP_DEFAULT_NAME = 'default'

    protected

    def authenticator_name
      GCP_DEFAULT_NAME
    end
  end
end

# frozen_string_literal: true

require_relative './authenticator_base_type'

module AuthenticatorsV2
  class AzureAuthenticatorType < AuthenticatorBaseType

    # Extracts and structures authentication parameters for AZURE authenticator.
    #
    # @param [Hash] authenticator_params - Hash containing authentication parameters.
    # @return [Hash, nil] - Returns a structured hash of relevant parameters or `nil` if none exist.
    def add_data_params(authenticator_params)
      data_section = {}
      azure_authentication_param = :provider_uri
      # Add provider_uri if it exists in `authenticator_params`
      value = retrieve_authenticator_variable(authenticator_params, azure_authentication_param)
      data_section[azure_authentication_param] = value if value

      data_section
    end
  end
end

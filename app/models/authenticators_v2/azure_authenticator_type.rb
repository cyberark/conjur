# frozen_string_literal: true

require_relative './authenticator_base_type'

module AuthenticatorsV2
  class AzureAuthenticatorType < AuthenticatorBaseType

    # Extracts and structures authentication parameters for AZURE authenticator.
    #
    # @param [Hash] authenticator_params - Hash containing authentication parameters.
    # @return [Hash, nil] - Returns a structured hash of relevant parameters or `nil` if none exist.
    def data
      return {} if @variables.blank?
        
      { provider_uri: format_field(@variables[:provider_uri]) }.compact
    end
  end
end

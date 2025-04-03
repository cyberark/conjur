# frozen_string_literal: true

require_relative './authenticator_base_type'

module AuthenticatorsV2
  class K8sAuthenticatorType < AuthenticatorBaseType
    def add_data_params(authenticator_params)
      return {} if authenticator_params.blank?

      fields = %i[
        kubernetes/service_account_token
        kubernetes/ca_cert
        kubernetes/api_url
        ca/cert
        ca/key
      ]

      fields.each_with_object({}) do |key, data_field|
        data_field[key] = retrieve_authenticator_variable(authenticator_params, key)
      end.compact
    end
  end
end

# frozen_string_literal: true

module AuthenticatorsV2
  class K8sAuthenticatorType < AuthenticatorBaseType
    def data
      return {} if @variables.blank?

      fields = %i[
        kubernetes/service_account_token
        kubernetes/ca_cert
        kubernetes/api_url
        ca/cert
        ca/key
      ]

      filter_variables(fields)
    end
  end
end

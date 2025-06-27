# frozen_string_literal: true

require_relative './authenticator_base_type'

module AuthenticatorsV2
  class LdapAuthenticatorType < AuthenticatorBaseType
    def initialize(
      authenticator_dict
    )
      super(authenticator_dict)

      @bind_password = variables&.fetch(:bind_password, nil)
      @tls_ca_cert = variables&.fetch(:tls_ca_cert, nil)
    end

    def add_data_params(variables)
      return nil if variables.blank?

      fields = %i[
        bind_password
        tls_ca_cert
      ]

      fields.each_with_object({}) do |key, data_field|
        data_field[key] = retrieve_authenticator_variable(variables, key)
      end.compact
    end

  end
end

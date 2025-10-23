# frozen_string_literal: true

module AuthenticatorsV2
  class LdapAuthenticatorType < AuthenticatorBaseType
    def initialize(
      authenticator_dict
    )
      super(authenticator_dict)

      @bind_password = variables&.fetch(:bind_password, nil)
      @tls_ca_cert = variables&.fetch(:tls_ca_cert, nil)
    end

    def data
      return {} if @variables.blank?

      filter_variables(%i[bind_password tls_ca_cert])
    end

  end
end

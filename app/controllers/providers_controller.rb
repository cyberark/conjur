# frozen_string_literal: true

class ProvidersController < ApplicationController
  def index
    authenticator_klass = Authentication::AuthnOidc::V2::DataObjects::Authenticator
    contract = Authentication::AuthnOidc::V2::Validations::AuthenticatorConfiguration
    validator = DB::Validation.new(contract)

    authenticators = DB::Repository::AuthenticatorRepository.new.find_all(
      account: params[:account],
      type: params[:authenticator]
    ).bind do |authenticators_data|
      authenticators_data.map do |authenticator_data|
        # perform validation on each record
        verified_data = validator.validate(authenticator_data)
        if verified_data.success?
          authenticator_klass.new(**verified_data.result)
        end
      end.compact
    end

    render(
      json: Authentication::AuthnOidc::V2::Views::ProviderContext.new.call(
        authenticators: authenticators
      )
    )
  end
end

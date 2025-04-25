# frozen_string_literal: true

class ProvidersController < ApplicationController
  def index
    contract = Authentication::AuthnOidc::V2::Validations::AuthenticatorConfiguration
    validator = DB::Validation.new(contract)

    authenticators = DB::Repository::AuthenticatorRepository.new.find_all(
      account: params[:account],
      type: params[:authenticator]
    ).bind do |response|
      response.map do |authenticator|
        # perform validation on each record
        validator.validate(authenticator.provider_details).bind do
          authenticator
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

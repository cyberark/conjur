# frozen_string_literal: true

class ProvidersController < ApplicationController
  def index
    namespace = Authentication::Util::NamespaceSelector.select(
      authenticator_type: params[:authenticator]
    )
    authenticator_klass = "#{namespace}::DataObjects::Authenticator".constantize
    validations = "#{namespace}::Validations::AuthenticatorConfiguration".constantize.new(
      utils: ::Util::ContractUtils
    )
    validator = DB::Validation.new(validations: validations)

    authenticators = DB::Repository::AuthenticatorRepository.new.find_all(
      account: params[:account],
      type: params[:authenticator]
    ).bind do |authenticators_data|
      authenticators_data.map do |authenticator_data|
        # perform validation on each record
        verified_data = validator.validate(data: authenticator_data)
        if verified_data.success?
          authenticator_klass.new(**verified_data.result)
        end
      end.compact
    end

    render(
      json: "#{namespace}::Views::ProviderContext".constantize.new.call(
        authenticators: authenticators
      )
    )
  end
end

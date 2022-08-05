# frozen_string_literal: true

class ProvidersController < ApplicationController
  def index
    namespace = Authentication::Util::NamespaceSelector.select(
      authenticator_type: params[:authenticator]
    )
    render(
      json: "#{namespace}::Views::ProviderContext".constantize.new.call(
        authenticators: DB::Repository::AuthenticatorRepository.new(
          data_object:  "#{namespace}::DataObjects::Authenticator".constantize
        ).find_all(
          account: params[:account],
          type: params[:authenticator]
        )
      )
    )
  end
end

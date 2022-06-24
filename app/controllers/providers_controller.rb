# frozen_string_literal: true

# require 'app/domain/authentication/util/namespace_selector'

class ProvidersController < RestController
  include FindResource
  include AssumedRole
  include CurrentUser

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
        ).select { |authenticator| role&.allowed_to?(:read, ::Resource[authenticator.resource_id]) }
      )
    )
  end

  # The v5 API currently sends +acting_as+ when listing resources
  # for a role other than the current user.
  def role
    assumed_role(params[:role].presence) || assumed_role(params[:acting_as].presence)
  end
end

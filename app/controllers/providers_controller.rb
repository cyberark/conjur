# frozen_string_literal: true

module Authenticators
  module Oidc
    class ProvidersController < RestController
      include FindResource
      include AssumedRole
      include CurrentUser

      def index
        available_authenticators = Contexts::Authenticators::AvailableAuthenticators.new
        render(
          json: available_authenticators.call(
            account: params[:account],
            role: params[:role].presence || params[:acting_as].presence
          )
        )
      end
    end
  end
end

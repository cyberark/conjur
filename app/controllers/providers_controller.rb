# frozen_string_literal: true
module Authenticators
  module Oidc
    class ProvidersController < RestController
      include FindResource
      include AssumedRole
      include CurrentUser

      def index
        # Rails 5 requires parameters to be explicitly permitted before converting
        # to Hash.  See: https://stackoverflow.com/a/46029524
        allowed_params = %i[account]
        
        render(
          json: Contexts::Authenticators::AvailableAuthenticators.new.call(
            role: role,
            account: params[:account]
          )
        )
        
      end

      # The v5 API currently sends +acting_as+ when listing resources
      # for a role other than the current user.
      def role
        assumed_role(params[:role].presence) || assumed_role(params[:acting_as].presence)
      end
    end
  end
end

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

        begin
          scope =  authenticators(
            role: assumed_role(query_role),
            repository: DB::Repository::AuthenticatorRepository.new,
            handler: Authentication::Handler::OidcAuthenticationHandler.new,
            **options(allowed_params)
          )
        rescue ApplicationController::Forbidden
          raise
        rescue ArgumentError => e
          raise ApplicationController::UnprocessableEntity, e.message
        end

        render(json: scope)
      end

      def show
        # Rails 5 requires parameters to be explicitly permitted before converting
        # to Hash.  See: https://stackoverflow.com/a/46029524
        allowed_params = %i[account service_id]

        begin
          scope =  authenticator(
            role: assumed_role(query_role),
            repository: DB::Repository::AuthenticatorRepository.new,
            handler: Authentication::Handler::OidcAuthenticationHandler.new,
            **options(allowed_params)
          )
        rescue ApplicationController::Forbidden
          raise
        rescue ArgumentError => e
          raise ApplicationController::UnprocessableEntity, e.message
        end

        render(json: scope)
      end

      # The v5 API currently sends +acting_as+ when listing resources
      # for a role other than the current user.
      def query_role
        params[:role].presence || params[:acting_as].presence
      end

      def options(allowed_params)
        params.permit(*allowed_params)
          .slice(*allowed_params).to_h.symbolize_keys
      end

      def authenticator(role:, repository:, handler:, account:, service_id:)
        authn = repository.find(account: account, type: "oidc", service_id: service_id)
        return {} unless authn

        if handler.can_use_authenticator?(authn, role)
          handler.generate_login_url(authn)
        else
          {}
        end
      end

      def authenticators(role:, repository:, handler:, account:)
        repository.find_all(
          account: account,
          type: "oidc"
        ).select{|authn| handler.can_use_authenticator?(authn, role) }.map do |authn|
          {
            name: authn.name,
            login_url: handler.generate_login_url(authn)
          }
        end
      end
    end
  end
end

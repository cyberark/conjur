# frozen_string_literal: true

module Contexts
  module Authenticators
    class AvailableAuthenticators
      def initialize(
        repository: DB::Repository::AuthenticatorRepository.new,
        handler: Authentication::Handler::OidcAuthenticationHandler.new
      )
        @repository = repository
        @handler = handler
      end

      def call(account:, role:)
        @repository.find_all(
          account: account,
          type: 'oidc'
        ).select { |authenticator| role.allowed_to?('authenticate', Role[authenticator.resource_id]) }
          .map do |authenticator|
            {
              service_id: authenticator.service_id,
              redirect_uri: @handler.generate_login_url(authenticator)
            }
          end
      end
    end
  end
end

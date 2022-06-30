module Contexts
  module Authenticators
    class AvailableAuthenticators
      def initialize(
        repository: ::DB::Repository::AuthenticatorRepository.new,
        handler: Authentication::Handler::OidcAuthenticationHandler.new,
        resource: ::Resource
      )
        @repository = repository
        @handler = handler
        @resource = resource
      end

      def call(role:, account:)
        # Get the Authenticator Objects
        # Select the ones that the user can see
        # Return list of authenticators
        # authenticators =  @repository.find_all(account: account,type: "oidc")

        @repository.find_all(account: account, type: "oidc")
        authenticators =  @repository.find_all(
          account: account,
          type: "oidc"
        ).select do |authn|
          role&.allowed_to?("authenticate", @resource[resource_id: authn.resource_id])
        end
        authenticators.map do |authn|
          {
            service_id: authn.name,
            redirect_uri: @handler.generate_login_url(authn)
          }
        end
      end
    end
  end
end

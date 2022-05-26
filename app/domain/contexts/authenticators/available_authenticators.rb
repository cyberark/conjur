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
        authenticators =  @repository.find_all(
          account: account,
          type: "oidc"
        ).select do |authn|
          role&.allowed_to?(
            'authenticate', @resource[resource_id: authn.resource_id])
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

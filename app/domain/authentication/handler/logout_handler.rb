# frozen_string_literal: true

module Authentication
  module Handler
    class LogoutHandler
      def initialize(
        authenticator_type:,
        authn_repo: DB::Repository::AuthenticatorRepository,
        namespace_selector: Authentication::Util::NamespaceSelector,
        logger: Rails.logger
      )
        @authenticator_type = authenticator_type
        @authn_repo = authn_repo
        @logger = logger

        # Dynamically load authenticator specific classes
        @namespace = namespace_selector.select(
          authenticator_type: authenticator_type
        )

        @identity_resolver = "#{@namespace}::ResolveIdentity".constantize
        @authn_repo = authn_repo.new(
          data_object: "#{@namespace}::DataObjects::Authenticator".constantize
        )
      end

      def call(parameters:, request_ip:)
        begin
          @logout = "#{@namespace}::Logout".constantize
        rescue NameError => e
          raise Errors::Authentication::Handler::LogoutNotImplemented(@namespace)
        end

        # Load Authenticator policy and values (validates data stored as variables)
        authenticator = @authn_repo.find(
          type: @authenticator_type,
          account: parameters[:account],
          service_id: parameters[:service_id]
        )

        @logout.new(
          authenticator: authenticator
        ).callback(parameters)

        # TODO: Add audit logging for success and failure. This will probably
        # require resolving the provided refresh token to a Conjur identity.
        # This functionality already exists in the AuthenticationHandler class -
        # maybe combining these classes would make sense.
      end
    end
  end
end

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
        namespace = namespace_selector.select(
          authenticator_type: authenticator_type
        )
        # TODO: raise exception if the authenticator does not include
        # logout functionality.
        @logout = "#{namespace}::Logout".constantize
      end

      def call(parameters:, request_ip:)
        # Load Authenticator policy and values (validates data stored as variables)
        authenticator = @authn_repo.find(
          type: @authenticator_type,
          account: parameters[:account],
          service_id: parameters[:service_id]
        )

        @logout.new(
          authenticator: authenticator
        ).callback(parameters)

        # TODO: Add audit event for success and failure
      end
    end
  end
end

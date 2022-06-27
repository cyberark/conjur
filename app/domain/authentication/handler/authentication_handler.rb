# frozen_string_literal: true

module Authentication
  module Handler
    class AuthenticationHandler
      def initialize(
        authenticator_type:,
        role: ::Role,
        resource: ::Resource,
        authn_repo: DB::Repository::AuthenticatorRepository,
        namespace_selector: Authentication::Util::NamespaceSelector
      )
        @role = role
        @resource = resource
        @authenticator_type = authenticator_type

        # Dynamically load authenticator specific classes
        namespace = namespace_selector.select(
          authenticator_type: authenticator_type
        )

        @identity_resolver = "#{namespace}::ResolveIdentity".constantize
        @strategy = "#{namespace}::Strategy".constantize
        @authn_repo = authn_repo.new(
          data_object: "#{namespace}::DataObjects::Authenticator".constantize
        )
      end

      def call(parameters:, request_ip:)
        # Load Authenticator policy and values (validates data stored as variables)
        authenticator = @authn_repo.find(
          type: @authenticator_type,
          account: parameters[:account],
          service_id: parameters[:service_id]
        )

        raise Errors::Conjur::RequestedResourceNotFound, "Unable to find authenticator with account: #{parameters[:account]} and service-id: #{parameters[:service_id]}" unless authenticator != nil

        role = @identity_resolver.new.call(
          identity: @strategy.new(
            authenticator: authenticator
          ).callback(parameters),
          account: parameters[:account],
          allowed_roles: @role.that_can(
            :authenticate,
            @resource[authenticator.resource_id]
          ).all
        )

        raise 'failed to authenticate' unless role

        unless role.valid_origin?(request_ip)
          raise Errors::Authentication::InvalidOrigin
        end

        log_audit_success(authenticator, role, request_ip, @authenticator_type)

        TokenFactory.new.signed_token(
          account: parameters[:account],
          username: role.role_id.split(':').last
        )
      end

      def log_audit_success(authenticator, conjur_role, client_ip, type)
        ::Authentication::LogAuditEvent.new.call(
          authentication_params:
            Authentication::AuthenticatorInput.new(
              authenticator_name: "#{type}",
              service_id: authenticator.service_id,
              account: authenticator.account,
              username: conjur_role.role_id,
              client_ip: client_ip,
              credentials: nil,
              request: nil
            ),
          audit_event_class: Audit::Event::Authn::Authenticate,
          error: nil
        )
      end
    end
  end
end

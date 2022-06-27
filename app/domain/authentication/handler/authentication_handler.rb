# frozen_string_literal: true

module Authentication
  module Handler
    class AuthenticationHandler
      def initialize(
        authenticator_type:,
        role: ::Role,
        resource: ::Resource,
        authn_repo: DB::Repository::AuthenticatorRepository,
        namespace_selector: Authentication::Util::NamespaceSelector,
        logger: Rails.logger
      )
        @role = role
        @resource = resource
        @authenticator_type = authenticator_type
        @logger = logger

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
        raise Errors::Authentication::RequestBody::MissingRequestParam, parameters[:code] unless parameters[:code]
        raise Errors::Authentication::RequestBody::MissingRequestParam, parameters[:state] unless parameters[:state]
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
      rescue => e
        log_audit_failure(parameters[:account], parameters[:service_id], request_ip, @authenticator_type, e)
        handle_oidc_authentication_error(e)
      end

      def handle_oidc_authentication_error(err)
        authentication_error = LogMessages::Authentication::AuthenticationError.new(err.inspect)
        @logger.warn(authentication_error)

        case err
        when Errors::Authentication::Security::RoleNotAuthorizedOnResource
          raise ApplicationController::Forbidden

        when Errors::Authentication::RequestBody::MissingRequestParam,
          Errors::Authentication::AuthnOidc::TokenVerificationFailed
          raise ApplicationController::BadRequest

        when Errors::Conjur::RequestedResourceNotFound
          raise ApplicationController::RecordNotFound.new(err.message)

        when Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
          raise ApplicationController::Unauthorized

        when Errors::Authentication::Jwt::TokenExpired
          raise ApplicationController::Unauthorized.new(err.message, true)

        when Errors::Authentication::AuthnOidc::StateMismatch,
          Errors::Authentication::Security::RoleNotFound
          raise ApplicationController::BadRequest

          # Code value mismatch
        when Rack::OAuth2::Client::Error
          raise ApplicationController::BadRequest

        else
          raise ApplicationController::Unauthorized
        end
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

      def log_audit_failure(account, service_id, client_ip, type, error)
        ::Authentication::LogAuditEvent.new.call(
          authentication_params:
            Authentication::AuthenticatorInput.new(
              authenticator_name: "#{type}",
              service_id: service_id,
              account: account,
              username: nil,
              client_ip: client_ip,
              credentials: nil,
              request: nil
            ),
          audit_event_class: Audit::Event::Authn::Authenticate,
          error: error
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

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
        logger: Rails.logger,
        authentication_error: LogMessages::Authentication::AuthenticationError,
        pkce_support_enabled: Rails.configuration.feature_flags.enabled?(:pkce_support)
      )
        @role = role
        @resource = resource
        @authenticator_type = authenticator_type
        @logger = logger
        @authentication_error = authentication_error
        @pkce_support_enabled = pkce_support_enabled

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
        unless @pkce_support_enabled
          required_parameters = %i[state code]
          required_parameters.each do |parameter|
            if !parameters.key?(parameter) || parameters[parameter].strip.empty?
              raise Errors::Authentication::RequestBody::MissingRequestParam, parameter
            end
          end
        end

        # Load Authenticator policy and values (validates data stored as variables)
        authenticator = @authn_repo.find(
          type: @authenticator_type,
          account: parameters[:account],
          service_id: parameters[:service_id]
        )

        if authenticator.nil?
          raise(
            Errors::Conjur::RequestedResourceNotFound,
            "Unable to find authenticator with account: #{parameters[:account]} and service-id: #{parameters[:service_id]}"
          )
        end

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

        # TODO: Add an error message
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
        handle_error(e)
      end

      def handle_error(err)
        @logger.info("#{err.class.name}: #{err.message}")

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

        when Errors::Authentication::Security::MultipleRoleMatchesFound
          raise ApplicationController::Forbidden
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
    end
  end
end

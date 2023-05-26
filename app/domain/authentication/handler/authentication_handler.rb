# frozen_string_literal: true

module Authentication
  module Handler
    class AuthenticationHandler
      def initialize(
        authenticator_type:,
        authn_repo: DB::Repository::AuthenticatorRepository,
        namespace_selector: Authentication::Util::NamespaceSelector,
        logger: Rails.logger,
        audit_logger: ::Audit.logger,
        authentication_error: LogMessages::Authentication::AuthenticationError,
<<<<<<< HEAD
        available_authenticators: Authentication::InstalledAuthenticators,
        role_repository: DB::Repository::AuthenticatorRoleRepository.new
=======
        available_authenticators: Authentication::InstalledAuthenticators
>>>>>>> 4f861170 (Authn-JWT refactor)
      )
        @authenticator_type = authenticator_type
        @logger = logger
        @audit_logger = audit_logger
        @authentication_error = authentication_error
        @available_authenticators = available_authenticators
<<<<<<< HEAD
        @role_repository = role_repository
=======
>>>>>>> 4f861170 (Authn-JWT refactor)

        # Dynamically load authenticator specific classes
        namespace = namespace_selector.select(
          authenticator_type: authenticator_type
        )

        @strategy = "#{namespace}::Strategy".constantize
        @authn_repo = authn_repo.new(
          data_object: "#{namespace}::DataObjects::Authenticator".constantize
        )
      end

<<<<<<< HEAD
      def params_allowed
        allowed = %i[authenticator service_id account]
        allowed += @strategy::ALLOWED_PARAMS if @strategy.const_defined?('ALLOWED_PARAMS')
        allowed
      end

=======
>>>>>>> 4f861170 (Authn-JWT refactor)
      def call(request_ip:, parameters:, request_body: nil, action: nil)
        # verify authenticator is whitelisted....
        unless @available_authenticators.enabled_authenticators.include?("#{parameters[:authenticator]}/#{parameters[:service_id]}")
          raise Errors::Authentication::Security::AuthenticatorNotWhitelisted, "#{parameters[:authenticator]}/#{parameters[:service_id]}"
        end

        # Load Authenticator policy and values (validates data stored as variables)
        authenticator = @authn_repo.find(
          type: @authenticator_type,
          account: parameters[:account],
          service_id: parameters[:service_id]
        )

        # TODO: this error should be in the auth repository
        if authenticator.nil?
          raise(
            Errors::Conjur::RequestedResourceNotFound,
            "#{parameters[:account]}:webservice:conjur/#{parameters[:authenticator]}/#{parameters[:service_id]}"
          )
        end

        role_identifier = @strategy.new(
          authenticator: authenticator
        ).callback(parameters: parameters, request_body: request_body)

        role = @role_repository.find(
          role_identifier: role_identifier,
          authenticator: authenticator
        )

        # Verify that the identified role is permitted to use this authenticator
        RBAC::Permission.new.permitted?(
          role_id: role.id,
          resource_id: "#{parameters[:account]}:webservice:conjur/#{@authenticator_type}/#{parameters[:service_id]}",
          privilege: :authenticate
        )

        # Add an error message (this may actually never be hit as we raise
        # upstream if there is a problem with authentication & lookup)
        raise Errors::Authorization::AuthenticationFailed unless role

        unless role.valid_origin?(request_ip)
          raise Errors::Authentication::InvalidOrigin
        end

        log_audit_success(authenticator, role.role_id, request_ip, @authenticator_type)

        TokenFactory.new.signed_token(
          account: parameters[:account],
          username: role.login,
          user_ttl: authenticator.token_ttl
        )
      rescue => e
        log_audit_failure(authenticator, role&.role_id, request_ip, @authenticator_type, e)
        handle_error(e)
      end

      def find_allowed_roles(resource_id)
        @role.that_can(
          :authenticate,
          @resource[resource_id]
        ).all.select(&:resource?).map do |role|
          {
            role_id: role.id,
            annotations: {}.tap { |h| role.resource.annotations.each {|a| h[a.name] = a.value }}
          }
        end
      end

      def handle_error(err)
        # Log authentication errors (but don't raise...)
        authentication_error = LogMessages::Authentication::AuthenticationError.new(err.inspect)
        @logger.info(authentication_error)

        @logger.info("#{err.class.name}: #{err.message}")
        err.backtrace.each {|l| @logger.info(l) }

        case err
        when Errors::Authentication::Security::RoleNotAuthorizedOnResource,
          Errors::Authentication::Security::MultipleRoleMatchesFound
          raise ApplicationController::Forbidden

        when Errors::Authentication::RequestBody::MissingRequestParam,
          Errors::Authentication::AuthnOidc::TokenVerificationFailed,
          Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
          Rack::OAuth2::Client::Error # Code value mismatch
          raise ApplicationController::BadRequest

        when Errors::Conjur::RequestedResourceNotFound,
          Errors::Authentication::Security::RoleNotFound,
          Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty,
          Errors::Authentication::Security::AuthenticatorNotWhitelisted
          raise ApplicationController::Unauthorized

        when Errors::Authentication::Jwt::TokenExpired
          raise ApplicationController::Unauthorized.new(err.message, true)

        else
          raise ApplicationController::Unauthorized
        end
      end

      def log_audit_success(service, role_id, client_ip, type)
        @audit_logger.log(
          ::Audit::Event::Authn::Authenticate.new(
            authenticator_name: type,
            service: service,
            role_id: role_id,
            client_ip: client_ip,
            success: true,
            error_message: nil
          )
        )
      end

      def log_audit_failure(service, role_id, client_ip, type, error)
        @audit_logger.log(
          ::Audit::Event::Authn::Authenticate.new(
            authenticator_name: type,
            service: service,
            role_id: role_id,
            client_ip: client_ip,
            success: false,
            error_message: error.message
          )
        )
      end
    end
  end
end

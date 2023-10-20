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
        available_authenticators: Authentication::InstalledAuthenticators,
        role_repository: DB::Repository::AuthenticatorRoleRepository,
        authorization: RBAC::Permission.new,
        token_factory: TokenFactory.new
      )
        @authenticator_type = authenticator_type
        @logger = logger
        @audit_logger = audit_logger
        @authentication_error = authentication_error
        @available_authenticators = available_authenticators
        @role_repository = role_repository
        @authorization = authorization
        @token_factory = token_factory

        # Dynamically load authenticator specific classes
        @namespace = namespace_selector.select(
          authenticator_type: authenticator_type
        )

        @strategy = "#{@namespace}::Strategy".constantize
        @authn_repo = authn_repo.new(
          data_object: "#{@namespace}::DataObjects::Authenticator".constantize,
          validations: set_if_present { "#{@namespace}::Validations::AuthenticatorConfiguration".constantize.new(utils: ::Util::ContractUtils) }
        )
      end

      def call(request_ip:, parameters:, request_body: nil, action: nil)
        authenticator_identifier = [parameters[:authenticator], parameters[:service_id]].compact.join('/')
        authenticator = retrieve_authenticator(
          identifier: authenticator_identifier,
          account: parameters[:account],
          service_id: parameters[:service_id]
        )

        role_identifier_response = @strategy.new(
          authenticator: authenticator
        ).callback(parameters: parameters, request_body: request_body)

        if role_identifier_response.success?
          role_identifier = role_identifier_response.result
        else
          if role_identifier_response.message.is_a?(Authentication::Base::RoleIdentifier)
            role = role_identifier_response.message.role_identifier
          end
          raise role_identifier_response.exception
        end

        role = @role_repository.new(
          authenticator: authenticator,
          role_contract: @role_contract
        ).find(
          role_identifier: role_identifier
        )

        # Add an error message (this may actually never be hit as we raise
        # upstream if there is a problem with authentication & lookup)
        raise Errors::Authorization::AuthenticationFailed unless role

        permitted?(
          role: role,
          authenticator_identifier: authenticator_identifier,
          account: parameters[:account]
        )

        unless role.valid_origin?(request_ip)
          raise Errors::Authentication::InvalidOrigin
        end

        log_audit_success(authenticator, role.role_id, request_ip, authenticator.type)

        @token_factory.signed_token(
          account: parameters[:account],
          username: role.login,
          user_ttl: authenticator.token_ttl
        )
      rescue => e
        role_identifier = role.is_a?(String) ? role : role&.role_id
        log_audit_failure(authenticator, role_identifier, request_ip, authenticator&.type, e)
        handle_error(e)
      end

      private

      def params_allowed
        allowed = %i[authenticator service_id account]
        allowed += @strategy::ALLOWED_PARAMS if @strategy.const_defined?('ALLOWED_PARAMS')
        allowed
      end

      def set_if_present(&block)
        block.call
      rescue NameError
        nil
      end

      def permitted?(role:, authenticator_identifier:, account:)
        return true if @available_authenticators.native_authenticators.include?(authenticator_identifier)

        # Verify that the identified role is permitted to use this authenticator
        @authorization.permitted?(
          role_id: role.id,
          resource_id: "#{account}:webservice:conjur/#{authenticator_identifier}",
          privilege: :authenticate
        )
      end


      def retrieve_authenticator(identifier:, service_id:, account:)
        # verify authenticator is whitelisted....
        unless @available_authenticators.enabled_authenticators.include?(identifier)
          raise Errors::Authentication::Security::AuthenticatorNotWhitelisted, identifier
        end

        if @available_authenticators.native_authenticators.include?(identifier)
          set_if_present do
            "#{@namespace}::DataObjects::Authenticator".constantize.new(
              account: account
            )
          end
        else
          # Load Authenticator policy and values (validates data stored as variables)
          @authn_repo.find(
            type: @authenticator_type,
            account: account,
            service_id: service_id
          )
        end
      end

      def handle_error(err)
        # Log authentication errors (but don't raise...)
        authentication_error = LogMessages::Authentication::AuthenticationError.new(err.inspect)
        @logger.info(authentication_error)

        @logger.info("#{err.class.name}: #{err.message}")
        err.backtrace.each {|l| @logger.info(l) }

        case err
        when Errors::Authentication::Security::RoleNotAuthorizedOnResource
          raise ApplicationController::Forbidden

        when Errors::Authentication::RequestBody::MissingRequestParam,
          Errors::Authentication::Security::RoleNotFound,
          Errors::Authentication::Security::AuthenticatorNotWhitelisted,
          Errors::Authentication::AuthnOidc::TokenVerificationFailed,
          Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
          Rack::OAuth2::Client::Error # Code value mismatch
          raise ApplicationController::BadRequest

        when Errors::Conjur::RequestedResourceNotFound,
          Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
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

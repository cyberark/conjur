# frozen_string_literal: true

module Authentication
  module Handler
    class AuthenticationHandler
      def initialize(
        authenticator_type:,
        authenticator_repository: DB::Repository::AuthenticatorRepository.new,
        namespace_selector: Authentication::Util::NamespaceSelector,
        logger: Rails.logger,
        audit_logger: ::Audit.logger,
        authentication_error: LogMessages::Authentication::AuthenticationError,
        available_authenticators: Authentication::InstalledAuthenticators,
        role_repository: DB::Repository::AuthenticatorRoleRepository,
        authorization: RBAC::Permission.new,
        token_factory: TokenFactory.new,
        validator: DB::Validation
      )
        @authenticator_type = authenticator_type
        @logger = logger
        @audit_logger = audit_logger
        @authentication_error = authentication_error
        @available_authenticators = available_authenticators
        @role_repository = role_repository
        @authorization = authorization
        @token_factory = token_factory
        @authenticator_repository = authenticator_repository
        @validator = validator

        # Dynamically load authenticator specific classes
        namespace = namespace_selector.select(
          authenticator_type: authenticator_type
        )

        @strategy = "#{namespace}::Strategy".constantize
        @authenticator_klass = "#{namespace}::DataObjects::Authenticator".constantize
        @authenticator_validation = Util::KlassLoader.set_if_present do
          "#{namespace}::Validations::AuthenticatorConfiguration".constantize.new(
            utils: ::Util::ContractUtils
          )
        end
        # @role_validation = Util::KlassLoader.set_if_present { "#{@namespace}::Validations::RoleMappingValidations".constantize.new(utils: ::Util::ContractUtils) }

        @success = ::SuccessResponse
        @failure = ::FailureResponse
      end

      def call(request_ip:, parameters:, request_body: nil, action: nil)
        service_id = parameters[:service_id]
        account = parameters[:account]
        role_for_audit = nil
        identified_authenticator = nil

        response = retrieve_authenticator(service_id: service_id, account: account).bind do |authenticator|
          identified_authenticator = authenticator
          identify_role(authenticator: authenticator, parameters: parameters, request_body: request_body).bind do |role_identifier|
            retrieve_role(authenticator: authenticator, role_identifier: role_identifier).bind do |role|
              role_for_audit = role
              check_usage_permitted(role: role, authenticator: authenticator).bind do |check_permitted_role|
                check_origin_permitted(role: check_permitted_role, request_ip: request_ip).bind do |check_allowed_role|
                  log_audit_success(authenticator, check_allowed_role.role_id, request_ip, authenticator.type)
                  issue_authentication_token(account: account, login: check_allowed_role.login, ttl: authenticator.token_ttl).bind do |token|
                    log_audit_success(authenticator, role.role_id, request_ip, authenticator.type)
                    return @success.new(token)
                  end
                end
              end
            end
          end
        end

        if role_for_audit.present?
          role_identifier = role_for_audit.is_a?(String) ? role_for_audit : role_for_audit&.role_id
          log_audit_failure(identified_authenticator, role_identifier, request_ip, authenticator&.type, e)
        end

        response
      rescue => e
        @failure.new(e.message, exception: e)
      end

      def params_allowed
        allowed = %i[authenticator service_id account]
        allowed += @strategy::ALLOWED_PARAMS if @strategy.const_defined?('ALLOWED_PARAMS')
        allowed
      end

      private

      def issue_authentication_token(account:, login:, ttl:)
        @success.new(
          @token_factory.signed_token(
            account: account,
            username: login,
            user_ttl: ttl
          )
        )
      end

      def check_origin_permitted(role:, request_ip:)
        if role.valid_origin?(request_ip)
          @success.new(role)
        else
          @failure.new(
            role,
            status: :forbidden,
            exception: Errors::Authentication::InvalidOrigin
          )
        end
      end

      def check_usage_permitted(role:, authenticator:)
        return @success.new(role) if @available_authenticators.native_authenticators.include?(authenticator.identifier)

        # Verify that the identified role is permitted to use this authenticator
        @authorization.permitted?(
          role: role,
          resource_id: authenticator.resource_id,
          privilege: :authenticate
        )
      end

      def retrieve_role(authenticator:, role_identifier:)
        @role_repository.new(
          authenticator: authenticator
        ).find(
          role_identifier: role_identifier
        )
      end

      def identify_role(authenticator:, parameters:, request_body:)
        @strategy.new(
          authenticator: authenticator
        ).callback(parameters: parameters, request_body: request_body)
      end

      def retrieve_authenticator(service_id:, account:)
        identifier = [@authenticator_type, service_id].compact.join('/')

        # verify authenticator is whitelisted....
        unless @available_authenticators.enabled_authenticators.include?(identifier)
          return @failure.new(
            "Authenticator: '#{identifier}' is no enabled.",
            status: :bad_request,
            exception: Errors::Authentication::Security::AuthenticatorNotWhitelisted.new(identifier)
          )
        end

        # If this is a native authenticator (like API Key), it won't be stored
        # as webservice, so just load the authenticator.
        if @available_authenticators.native_authenticators.include?(identifier)
          @success.new(@authenticator_klass.new(account: account))
        else
          # Load Authenticator policy and variables
          @authenticator_repository.find(
            type: @authenticator_type,
            account: account,
            service_id: service_id
          ).bind do |authenticator_data|

            # validate data against authenticator specific validations
            @validator.new(
              validations: @authenticator_validation
            ).validate(data: authenticator_data).bind do |validated_authenticator_data|

              # Instantiate and return authenticator data object for future use
              @success.new(@authenticator_klass.new(**validated_authenticator_data))
            rescue => e
              @failure.new(e.message, exception: e)
            end
          end
        end
      end

      # def handle_error(err)
      #   # Log authentication errors (but don't raise...)
      #   authentication_error = LogMessages::Authentication::AuthenticationError.new(err.inspect)
      #   @logger.info(authentication_error)

      #   @logger.info("#{err.class.name}: #{err.message}")
      #   err.backtrace.each {|l| @logger.info(l) }

      #   case err
      #   when Errors::Authentication::Security::RoleNotAuthorizedOnResource
      #     raise ApplicationController::Forbidden

      #   when Errors::Authentication::RequestBody::MissingRequestParam,
      #     Errors::Authentication::Security::RoleNotFound,
      #     Errors::Authentication::Security::AuthenticatorNotWhitelisted,
      #     Errors::Authentication::AuthnOidc::TokenVerificationFailed,
      #     Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
      #     Rack::OAuth2::Client::Error # Code value mismatch
      #     raise ApplicationController::BadRequest

      #   when Errors::Conjur::RequestedResourceNotFound,
      #     Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
      #     raise ApplicationController::Unauthorized

      #   when Errors::Authentication::Jwt::TokenExpired
      #     raise ApplicationController::Unauthorized.new(err.message, true)

      #   else
      #     raise ApplicationController::Unauthorized
      #   end
      # end

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

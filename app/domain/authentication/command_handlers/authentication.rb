# frozen_string_literal: true

module Authentication
  module CommandHandlers
    class Authentication
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        authenticator_type:,
        authenticator_repository: ::DB::Repository::AuthenticatorRepository.new,
        klass_loader_library: ::Authentication::Util::V2::KlassLoader,
        logger: Rails.logger,
        audit_logger: ::Audit.logger,
        authentication_error: LogMessages::Authentication::AuthenticationError,
        available_authenticators: ::Authentication::InstalledAuthenticators,
        role_resource: ::Role,
        authorization: ::RBAC::Permission.new,
        token_factory: ::TokenFactory.new,
        validator: ::DB::Validation,
        configuration: Rails.application.config.conjur_config
      )
        @authenticator_type = authenticator_type
        @logger = logger
        @audit_logger = audit_logger
        @authentication_error = authentication_error
        @available_authenticators = available_authenticators
        @role_resource = role_resource
        @authorization = authorization
        @token_factory = token_factory
        @authenticator_repository = authenticator_repository
        @validator = validator
        @configuration = configuration

        klass_loader = klass_loader_library.new(authenticator_type)
        @strategy = klass_loader.strategy
        @authenticator_klass = klass_loader.data_object
        @authenticator_validation = klass_loader.authenticator_validation

        @success = ::SuccessResponse
        @failure = ::FailureResponse
      end
      # rubocop:enable Metrics/ParameterLists

      def call(request_ip:, parameters:, request_body: nil)
        service_id = parameters[:service_id]
        account = parameters[:account]
        role_for_audit = nil
        identified_authenticator = nil

        response = retrieve_authenticator(service_id: service_id, account: account).bind do |authenticator|
          identified_authenticator = authenticator
          identify_role(authenticator: authenticator, parameters: parameters, request_body: request_body).bind do |role_identifier|
            retrieve_role(role_identifier: role_identifier).bind do |role|
              role_for_audit = role
              check_usage_permitted(role: role, authenticator: authenticator).bind do |check_permitted_role|
                check_origin_permitted(role: check_permitted_role, request_ip: request_ip).bind do |check_allowed_role|
                  issue_authentication_token(account: account, login: check_allowed_role.login, ttl: authenticator.token_ttl).bind do |token|
                    log_audit_success(
                      service: authenticator,
                      role_id: role.role_id,
                      request_ip: request_ip,
                      authenticator_type: authenticator.type
                    )
                    return @success.new(token)
                  end
                end
              end
            end
          end
        end

        role_identifier = if role_for_audit.is_a?(String)
          role_for_audit
        elsif role_for_audit.nil? && parameters[:id].present?
          @role_resource.roleid_from_username(parameters[:account], parameters[:id])
        else
          role_for_audit&.role_id
        end

        log_audit_failure(
          service: identified_authenticator,
          role_id: role_identifier,
          request_ip: request_ip,
          authenticator_type: identified_authenticator&.type,
          error_message: response.message
        )

        response
      rescue => e
        @failure.new(e.message, exception: e, backtrace: e.backtrace)
      end

      def params_allowed
        allowed = %i[authenticator service_id account id]
        allowed += @strategy::ALLOWED_PARAMS if @strategy.const_defined?('ALLOWED_PARAMS')
        allowed
      end

      private

      def issue_authentication_token(account:, login:, ttl:)
        @success.new(
          @token_factory.signed_token(
            account: account,
            username: login,
            host_ttl: ttl || @configuration.host_authorization_token_ttl,
            user_ttl: ttl || @configuration.user_authorization_token_ttl
          )
        )
      end

      def check_origin_permitted(role:, request_ip:)
        if role.valid_origin?(request_ip)
          @logger.debug(LogMessages::Authentication::OriginValidated.new.to_s)
          @success.new(role)
        else
          @failure.new(
            role,
            status: :unauthorized,
            exception: Errors::Authentication::InvalidOrigin.new
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

      def retrieve_role(role_identifier:)
        role = @role_resource[role_identifier.identifier]
        return @success.new(role) if role

        @failure.new(
          "Failed to find role for: '#{role_identifier.identifier}'",
          exception: Errors::Authentication::Security::RoleNotFound.new(role_identifier.role_for_error),
          status: :bad_request
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
        unless @available_authenticators.enabled_authenticators.include?(identifier) || @available_authenticators.native_authenticators.include?(identifier)
          return @failure.new(
            "Authenticator: '#{identifier}' is not enabled.",
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
            @validator.new(@authenticator_validation)
              .validate(authenticator_data).bind do |validated_authenticator_data|
              # Instantiate and return authenticator data object for future use
              @success.new(@authenticator_klass.new(**validated_authenticator_data))
            end
          end
        end
      rescue => e
        @failure.new(e.message, exception: e)
      end

      def log_audit_success(service:, role_id:, request_ip:, authenticator_type:)
        @audit_logger.log(
          ::Audit::Event::Authn::Authenticate.new(
            authenticator_name: authenticator_type,
            service: service,
            role_id: role_id,
            client_ip: request_ip,
            success: true,
            error_message: nil
          )
        )
      end

      def log_audit_failure(service:, role_id:, request_ip:, authenticator_type:, error_message:)
        @audit_logger.log(
          ::Audit::Event::Authn::Authenticate.new(
            authenticator_name: authenticator_type,
            service: service,
            role_id: role_id,
            client_ip: request_ip,
            success: false,
            error_message: error_message
          )
        )
      end
    end
  end
end

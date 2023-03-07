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
        audit_logger: ::Audit.logger,
        authentication_error: LogMessages::Authentication::AuthenticationError,
        available_authenticators: Authentication::InstalledAuthenticators,
        pkce_support_enabled: Rails.configuration.feature_flags.enabled?(:pkce_support)
      )
        @role = role
        @resource = resource
        @authenticator_type = authenticator_type
        @logger = logger
        @audit_logger = audit_logger
        @authentication_error = authentication_error
        @pkce_support_enabled = pkce_support_enabled
        @available_authenticators = available_authenticators

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

      def call(request_ip:, parameters: nil, request_body: nil, action: nil)
        unless @pkce_support_enabled
          required_parameters = %i[state code]
          required_parameters.each do |parameter|
            if !parameters.key?(parameter) || parameters[parameter].strip.empty?
              raise Errors::Authentication::RequestBody::MissingRequestParam, parameter
            end
          end
        end

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

        if authenticator.nil?
          raise(
            Errors::Conjur::RequestedResourceNotFound,
            "Unable to find authenticator with account: #{parameters[:account]} and service-id: #{parameters[:service_id]}"
          )
        end

        # binding.pry

        role = @identity_resolver.new(authenticator: authenticator).call(
          identifier: @strategy.new(
            authenticator: authenticator
          ).callback(parameters: parameters, request_body: request_body),
          account: parameters[:account],
          id: parameters[:id],
          allowed_roles: @role.that_can(
            :authenticate,
            @resource[authenticator.resource_id]
          ).all.select(&:resource?)
        )

        # TODO: Add an error message
        raise 'failed to authenticate' unless role

        unless role.valid_origin?(request_ip)
          raise Errors::Authentication::InvalidOrigin
        end

        log_audit_success(authenticator, role.role_id, request_ip, @authenticator_type)

        TokenFactory.new.signed_token(
          account: parameters[:account],
          username: role.login,  # role.role_id.split(':').last,
          user_ttl: authenticator.token_ttl
        )
      rescue => e

          #   log_audit_failure(
  #     authn_params: authenticator_input,
  #     audit_event_class: Audit::Event::Authn::Authenticate,
  #     error: e
  #   )

        log_audit_failure(authenticator, role&.role_id, request_ip, @authenticator_type, e)
        handle_error(e)
      end

      def handle_error(err)
        @logger.info("#{err.class.name}: #{err.message}")
        # binding.pry
        err.backtrace.each {|l| @logger.info(l) }

        case err
        when Errors::Authentication::Security::RoleNotAuthorizedOnResource
          raise ApplicationController::Forbidden

        when Errors::Authentication::RequestBody::MissingRequestParam,
          Errors::Authentication::AuthnOidc::TokenVerificationFailed,
          Errors::Authentication::AuthnOidc::TokenRetrievalFailed
          raise ApplicationController::BadRequest

        when Errors::Conjur::RequestedResourceNotFound,
          Errors::Authentication::Security::RoleNotFound
          raise ApplicationController::Unauthorized
          # raise ApplicationController::RecordNotFound.new(err.message)

        when Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
          raise ApplicationController::Unauthorized

        when Errors::Authentication::Jwt::TokenExpired
          raise ApplicationController::Unauthorized.new(err.message, true)

        when Errors::Authentication::Security::RoleNotFound
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
        # binding.pry
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

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
        available_authenticators: Authentication::InstalledAuthenticators
      )
        @role = role
        @resource = resource
        @authenticator_type = authenticator_type
        @logger = logger
        @audit_logger = audit_logger
        @authentication_error = authentication_error
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

        if authenticator.nil?
          raise(
            Errors::Conjur::RequestedResourceNotFound,
            "Unable to find authenticator with account: #{parameters[:account]} and service-id: #{parameters[:service_id]}"
          )
        end

        begin
          role_id = @identity_resolver.new(authenticator: authenticator).call(
            identifier: @strategy.new(
              authenticator: authenticator
            ).callback(parameters: parameters, request_body: request_body),
            id: parameters[:id],
            allowed_roles: find_allowed_roles(authenticator.resource_id)
          )
          role = ::Role[role_id]
        rescue Errors::Authentication::Security::RoleNotFound => e
          # This is a bit dirty, but now that we've shifted from looking up to
          # selecting, this is needed to see if the role actually has permission
          missing_role = e.message.scan(/'(.+)'/).flatten.first
          identity = if missing_role.match(/^host\//)
            "#{parameters[:account]}:host:#{missing_role.gsub(/^host\//, '')}"
          else
            "#{parameters[:account]}:user:#{missing_role}"
          end
          if (role = @role[identity])
            if (webservice = @resource["#{parameters[:account]}:webservice:conjur/#{@authenticator_type}/#{parameters[:service_id]}"])
              unless @role[identity].allowed_to?(:authenticate, webservice)
                raise Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
                  missing_role,
                  :authenticate,
                  webservice.resource_id
                )
              end
            end
          end
          # If role or authenticator isn't present, raise the original exception
          raise e
        end

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
          Errors::Authentication::Security::RoleNotFound,
          Errors::Authentication::Security::AuthenticatorNotWhitelisted,
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

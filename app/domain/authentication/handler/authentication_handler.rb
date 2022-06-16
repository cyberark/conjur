module Authentication
  module Handler
    class AuthenticationHandler
      def initialize(
        authenticator_repository: ::DB::Repository::AuthenticatorRepository.new,
        token_factory: TokenFactory.new,
        role_repository_class: ::Role,
        role_repo: ::DB::Repository::RoleRepository.new,
        resource_repository_class: ::Resource,
        logger: Rails.logger
      )
        @authenticator_repository = authenticator_repository
        @token_factory = token_factory
        @role_repository_class = role_repository_class
        @role_repo = role_repo
        @resource_repository_class = resource_repository_class
        @logger = logger
      end

      def self.authenticate(account:, service_id:, parameters:)
        new.authenticate(account: account, service_id: service_id, parameters: parameters)
      end

      def authenticate(account:, service_id:, parameters:)
        validate_account_exists(account)
        authenticator = @authenticator_repository.find(
          type: type,
          account: account,
          service_id: service_id
        )

        raise Errors::Conjur::RequestedResourceNotFound, "Unable to find authenticator with account: #{account} and service-id: #{service_id}" if authenticator.nil?

        validate_authenticator(authenticator, service_id)
        validate_parameters_are_valid(authenticator, parameters)

        username = extract_and_verify_identity(authenticator, parameters)
        conjur_role = fetch_conjur_role(
          account: authenticator.account,
          identity: username,
          prefix: authenticator.authenticator_prefix
        )
        raise Errors::Authentication::Security::RoleNotFound, username unless conjur_role

        validate_identity_can_use_authenticator?(authenticator, conjur_role)

        validate_client_ip(parameters[:client_ip], conjur_role)

        log_audit_success(authenticator, conjur_role, parameters[:client_ip])

        generate_token(account, username)
      rescue => e
        log_audit_failure(account, service_id, parse_username(role: conjur_role, username: username), parameters[:client_ip], e)
        raise e
      end

      def parse_username(role:, username:)
        return username unless role

        role.role_id.split(':').last
      end

      def get_login_url(account:, service_id:)
        validate_account_exists(account)
        authenticator = @authenticator_repository.find(
          type: type,
          account: account,
          service_id: service_id
        )

        validate_authenticator(authenticator, service_id)

        generate_login_url(authenticator)
      end

      protected

      def generate_login_url(authenticator)
        raise NoMethodError
      end

      def validate_parameters_are_valid(authenticator, parameters)
        return unless authenticator.required_request_parameters

        authenticator.required_request_parameters.each do |param|
          raise Errors::Authentication::RequestBody::MissingRequestParam, param unless parameters[param.to_sym] && !parameters[param.to_sym].strip.empty?
        end
      end

      def extract_and_verify_identity(authenticator, parameters)
        identity = extract_identity(authenticator, parameters)
        if identity.to_s.empty?
          raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty,
                authenticator.claim_mapping
        end

        if identity == "admin"
          raise Errors::Authentication::AdminAuthenticationDenied, authenticator.authenticator_name
        end

        @logger.debug(
          LogMessages::Authentication::AuthnOidc::ExtractedUsernameFromIDToken.new(
            identity,
            authenticator.claim_mapping
          )
        )

        identity
      end

      def extract_identity(authenticator, parameters)
        raise NoMethodError
      end

      def type
        raise NoMethodError
      end

      def identity_required_privilege
        'authenticate'
      end

      private

      def validate_identity_can_use_authenticator?(authenticator, role)
        raise Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
          role.identifier,
          identity_required_privilege,
          authenticator.resource_id
        ) unless role&.allowed_to?(
          identity_required_privilege,
          @resource_repository_class[resource_id: authenticator.resource_id]
        )
      end

      def generate_token(account, identity)
        @token_factory.signed_token(
          account: account,
          username: identity
        )
      end

      def validate_client_ip(client_ip_address, conjur_role)
        raise Errors::Authentication::InvalidOrigin unless conjur_role.valid_origin?(client_ip_address)
      end

      def fetch_conjur_role(account:, identity:, prefix:)
        @role_repo.find(
          account: account,
          identifier: identity,
          name: "#{prefix}/identity"
        )
      end

      def validate_account_exists(account)
        raise Errors::Authentication::Security::AccountNotDefined, account if @role_repository_class.with_pk("#{account}:user:admin").nil?
      end

      def validate_authenticator(authenticator, service_id)
        raise Errors::Authentication::AuthenticatorNotSupported, "authn-#{type}/#{service_id}" unless authenticator && enabled?(authenticator)
        # raise Errors::Conjur::RequiredResourceMissing,  unless authenticator.valid?
      end

      def enabled?(authenticator)
        ::Authentication::InstalledAuthenticators
          .enabled_authenticators
          .include?(authenticator.authenticator_name)
      end

      def log_audit_success(authenticator, conjur_role, client_ip)
        ::Authentication::LogAuditEvent.new.call(
          authentication_params:
            Authentication::AuthenticatorInput.new(
              authenticator_name: "authn-#{type}",
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

      def log_audit_failure(account, service_id, username, client_ip, error)
        ::Authentication::LogAuditEvent.new.call(
          authentication_params:
            Authentication::AuthenticatorInput.new(
              authenticator_name: "authn-#{type}",
              service_id: service_id,
              account: account,
              username: username,
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

module Authentication
  module Handler
    class AuthenticationHandler
      def initialize(authenticator_repository: ::DB::Repository::AuthenticatorRepository.new, token_factory: TokenFactory.new)
        @authenticator_repository = authenticator_repository
        @token_factory = token_factory
      end

      def authenticate(account, service_id, parameters)
        validate_account_exists(account)
        authenticator = @authenticator_repository.find(
          type: type,
          account: account,
          service_id: service_id
        )

        validate_authenticator(authenticator)
        validate_parameters_are_valid(authenticator, parameters)

        conjur_role = fetch_conjur_role(
          authenticator.account,
          extract_identity(authenticator, parameters)
        )
        validate_identity_can_use_authenticator?(authenticator, conjur_role)

        validate_client_ip(parameters['client_ip'], conjur_role)

        return generate_token(account, conjur_role)
      end

      def get_login_url(account, service_id)
        validate_account_exists(account)
        authenticator = @authenticator_repository.find(
          type: type,
          account: account,
          service_id: service_id
        )

        validate_authenticator(authenticator)

        return generate_login_url(authenticator)
      end

      protected

      def generate_login_url(authenticator)
        raise NoMethodError
      end

      def validate_parameters_are_valid(authenticator, parameters)
        return unless authenticator.required_payload_parameters
        authenticator.required_payload_parameters.each do |param|
          raise "Required parameter #{param} is missing from parameters" unless
            parameters[param]
        end
      end

      def extract_identity(authenticator, parameters)
        raise NoMethodError
      end

      def type
        raise NoMethodError
      end

      def identity_required_privilege
        return 'authenticate'
      end

      private

      def validate_identity_can_use_authenticator?(authenticator, role)
        raise Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
          role.identifier,
          identity_required_privilege,
          authenticator.resource_id
        ) unless user_role.allowed_to?(
          identity_required_privilege,
           ::Resource[authenticator.resource_id]
        )
      end

      def generate_token(account, conjur_role)
        @token_factory.signed_token(
          account: account,
          username: conjur_role.identity
        )
      end

      def validate_client_ip(client_ip_address, conjur_role)
        raise Errors::Authentication::InvalidOrigin unless conjur_role.valid_origin?(client_ip_address)
      end

      def fetch_conjur_role(account, identity)
        return ::Role[::Role.roleid_from_username(account, identity)]
      end

      def validate_account_exists(account)
        raise Errors::Authentication::Security::AccountNotDefined, account unless ::Role.exists?["#{account}:user:admin"]
      end

      def validate_authenticator(authenticator)
        raise Errors::Authentication::AuthenticatorNotSupported unless authenticator &&
          authenticator.is_valid? &&
          is_enabled?(authenticator)
      end

      def is_enabled?(authenticator)
        ::Authentication::InstalledAuthenticators
          .enabled_authenticators
          .include?(authenticator.authenticator_name)
      end
    end
  end
end
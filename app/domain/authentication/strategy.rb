# frozen_string_literal: true

module Authentication

  # - Runs security checks
  # - Finds the appropriate authenticator
  # - Validates credentials against
  # - Returns a new token
  class Strategy < ::Dry::Struct

    AuthenticatorNotFound = ::Util::ErrorClass.new(
      "'{0}' wasn't in the available authenticators")
    InvalidCredentials = ::Util::ErrorClass.new(
      "Invalid credentials")


    class Input < ::Dry::Struct
      attribute :authenticator_name, ::Types::NonEmptyString
      attribute :service_id,         ::Types::NonEmptyString.optional
      attribute :account,            ::Types::NonEmptyString
      attribute :username,           ::Types::NonEmptyString
      attribute :password,           ::Types::String
      attribute :origin,             ::Types::NonEmptyString
      attribute :request,            ::Types::Any.optional # for k8s authenticator

      # Convert this Input to an Security::AccessRequest
      #
      def to_access_request(env)
        ::Authentication::Security::AccessRequest.new(
          webservice: webservice,
          whitelisted_webservices: ::Authentication::Webservices.from_string(
            account, env['CONJUR_AUTHENTICATORS'] ||
                       Authentication::Strategy.default_authenticator_name
          ),
          user_id: username
        )
      end

      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account:            account,
          authenticator_name: authenticator_name,
          service_id:         service_id
        )
      end
    end

    def self.default_authenticator_name
      'authn'
    end

    # required constructor parameters
    #
    attribute :authenticators, ::Types::Hash

    # optional constructor parameters
    #
    attribute :security, ::Types::Any.default{ ::Authentication::Security.new }
    attribute :env, ::Types::Any.default(ENV)
    attribute :token_factory, ::Types::Any.default{ TokenFactory.new }
    attribute :role_cls, ::Types::Any.default{ ::Role }
    attribute :audit_log, ::Types::Any.default{ AuditLog }

    def conjur_token(input)
      authenticator = authenticators[input.authenticator_name]

      validate_authenticator_exists(input, authenticator)
      validate_security(input)
      validate_credentials(input, authenticator)
      validate_origin(input)

      audit_success(input)
      new_token(input)

    rescue => e
      audit_failure(input, e)
      raise e
    end

    private

    def audit_success(input)
      audit_log.record_authn_event(
        role: role(input.username, input.account),
        webservice_id: input.webservice.resource_id,
        authenticator_name: input.authenticator_name,
        success: true
      )
    end

    def audit_failure(input, err)
      audit_log.record_authn_event(
        role: role(input.username, input.account),
        webservice_id: input.webservice.resource_id,
        authenticator_name: input.authenticator_name,
        success: false,
        message: err.message
      )
    end

    def role(username, account)
      role_cls.by_login(username, account: account)
    end

    def validate_authenticator_exists(input, authenticator)
      raise AuthenticatorNotFound, input.authenticator_name unless authenticator
    end

    def validate_security(input)
      security.validate(input.to_access_request(env))
    end

    def validate_credentials(input, authenticator)
      raise InvalidCredentials unless authenticator.valid?(input)
    end

    def validate_origin(input)
      authn_role = role(input.username, input.account)
      raise Unauthorized, "Invalid origin" unless authn_role.valid_origin?(input.origin)
    end

    def new_token(input)
      token_factory.signed_token(
        account: input.account,
        username: input.username
      )
    end
  end

end

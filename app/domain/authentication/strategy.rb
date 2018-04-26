module Authentication

  # - Runs security checks
  # - Finds the appropriate authenticator
  # - Validates credentials against
  # - Returns a new token
  class Strategy < ::Dry::Struct

    AuthenticatorNotFound = ::Util::ErrorClass.new(
      "'{0}' wasn't in the available authenticators")

    class Input < ::Dry::Struct
      attribute :authenticator_name, Types::NonEmptyString
      attribute :service_id,         Types::NonEmptyString.optional
      attribute :account,            Types::NonEmptyString
      attribute :username,           Types::NonEmptyString
      attribute :password,           Types::NonEmptyString
    end

    # required
    #
    attribute :authenticators, ::Types::Hash

    # optional
    #
    attribute :security, ::Types::Any.default(::Authentication::Security.new)
    attribute :env, ::Types::Any.default(ENV)
    attribute :role_class, ::Types::Any.default(::Authentication::MemoizedRole)
    attribute :token_factory, ::Types::Any.default(TokenFactory.new)

    def conjur_token(input)
      authenticator = authenticators[input.authenticator_name]

      validate_authenticator_exists(input, authenticator)
      validate_security(input)
      validate_credentials(input, authenticator)

      new_token(input)
    end

    private

    def validate_authenticator_exists(input, authenticator)
      raise AuthenticatorNotFound, input.authenticator_name unless authenticator
    end

    def validate_security(input)
      security.validate(security_access_request(input))
    end

    def validate_credentials(input, authenticator)
      raise Unauthorized unless authenticator.valid?(input)
    end

    def new_token(input)
      token_factory.signed_token(
        account: input.account,
        username: input.username
      )
    end

    private

    def security_access_request(input)
      ::Authentication::Security::AccessRequest.new(
        webservice: Webservice.new(
          account:            input.account,
          authenticator_name: input.authenticator_name,
          service_id:         input.service_id
        ),
        whitelisted_webservices: Webservices.from_string(
          # TODO We don't need to to check when it's conjur default
          input.account, conjur_authenticators
        ),
        user_id: input.username
      )
    end

    def conjur_authenticators
      # the default conjur authenticator is always available
      # TODO change this
      [env['CONJUR_AUTHENTICATORS'], 'authn'].compact.join(',')
    end
  end

end

# NOTES:
# The type is really "Authenticator", but... ruby.
#
require 'types'

module Authentication

  # - Runs security checks
  # - Finds the appropriate authenticator
  # - Runs it
  class Strategy < ::Dry::Struct

    # all optional
    attribute :authenticators, 
      ::Types.Array(::Types::Any).default(all_authenticators)
    attribute :security, ::Types::Any
    attribute :env, ::Types::Hash.default(ENV)
    attribute :role_class, ::Types::Any.default(::Authentication::MemoizedRole)
    attribute :token_factory, ::Types::Any.default(TokenFactory.new)

    class AuthenticatorNotFound < RuntimeError
      def initialize(auth_type)
        super("'#{auth_type}' wasn't in the available authenticators")
      end
    end

    class Input < ::Dry::Struct
      attribute :auth_type,  Types::NonEmptyString
      attribute :service_id, Types::NonEmptyString
      attribute :account,    Types::NonEmptyString
      attribute :username,   Types::NonEmptyString
      attribute :password,   Types::NonEmptyString
    end

    def self.all_authenticators
      # TODO Get this from lib/authentication/ subdirs
      # TODO Add one for Conjur
      # TODO Pass them ENV during construction
      {
        ldap: Authentication::Ldap::Authenticator#,
        # conjur: Authentication::Ldap::Authenticator
      }
    end

    def validate_authenticator_exists(input, authenticator)
      raise AuthenticatorNotFound, input.authn_type unless authenticator
    end

    def validate_security(input)
      security.validate(security_access_request(input))
    end

    def validate_credentials(input, authenticator)
      raise Unauthorized unless valid_login?(authenticator, input)
    end

    def conjur_token(input)
      authenticator = authenticators[input.authn_type.to_sym]

      validate_authenticator_exists(input, authenticator)
      validate_security(input)
      validate_credentials(input, authenticator)

      new_token(input)
    end

    def new_token(input)
    end

      role_id = MemoizedRole.roleid_from_username(account, username)

      #TODO remember kevins thing add the service_id and env

      case input.authn_type
      when 'authn-ldap'
        validate_security!(authenticator, account, service_id, username)
        raise Unauthorized unless ldap_authenticator.valid?(username, password)
        role = MemoizedRole[role_id]
      when 'authn' # default conjur auth
        credentials = Credentials[role_id]
        validate_credentials!(credentials, password)
        role = credentials.role
      else
        raise Unauthorized
      end

    end

    private

    def security_access_request(input)
      ::Authentication::Security::AccessRequest.new(
        webservice: Webservice.new(
          account:    input.account,
          auth_type:  input.auth_type,
          service_id: input.service_id
        ),
        whitelisted_webservices: Webservices.from_string(
          env['CONJUR_AUTHENTICATORS']
        ),
        user_id: input.username
      )
    end

    def valid_login?(input, authenticator)
      authenticator.valid?(input.username,
                           input.password,
                           input.service_id)
    end



    def validate_security!(authenticator, account, service_id, user_id)
      security = Authentication::Security.new(
        authn_type: authenticator, account: account, role_class: MemoizedRole
      )
      security.validate(service_id, user_id)
    rescue Authentication::NotEnabled, Authentication::ServiceNotDefined,
           Authentication::NotAuthorizedInConjur => e
      logger.debug(e.message)
      raise Unauthorized
    rescue => e
      logger.debug("Unexpected Authentication::Security Error: #{e.message}")
      raise Unauthorized
    end

  end

end

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
    InvalidOrigin = ::Util::ErrorClass.new(
      "Invalid origin")


    class Input < ::Dry::Struct
      attribute :authenticator_name, ::Types::NonEmptyString
      attribute :service_id,         ::Types::NonEmptyString.optional
      attribute :account,            ::Types::NonEmptyString
      attribute :username,           ::Types::NonEmptyString.optional
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

      # Creates a copy of this object with the attributes updated by those
      # specified in hash
      #
      def update(hash)
        self.class.new(to_hash.merge(hash))
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

    def login(input)
      authenticator = authenticators[input.authenticator_name]

      validate_authenticator_exists(input, authenticator)
      validate_security(input)

      key = authenticator.login(input)
      raise InvalidCredentials unless key

      audit_success(input)
      new_login(input, key)
    rescue => err
      audit_failure(input, err)
      raise err
    end

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

    # TODO: (later version) Extract this and related private methods into its
    # own object.  We'll need to break down Strategy into its component parts
    # to avoid repetition, and then use those parts in both the new
    # "OIDCStrategy" and this original Strategy.
    #
    # Or take a different approach that accomplishes the same goals
    #
    def conjur_token_oidc(input)
      authenticator = authenticators[input.authenticator_name]
      validate_authenticator_exists(input, authenticator)
      
      user_details = oidc_user_details(input)
      username = user_details.user_info.preferred_username
      input_with_username = input.update(username: username)

      validate_security(input_with_username)
      oidc_validate_credentials(input_with_username, user_details)
      validate_origin(input_with_username)

      audit_success(input_with_username)
      new_token(input_with_username)
    rescue => e
      audit_failure(input, e)
      raise e
    end

    private

    # NOTE: These two methods are "special" (outside the framework) by design.
    # We already know that the OIDC authenticator doesn't fit within this
    # framework design, and will be pulling it out into multiple routes and its
    # own objects on the next iteration.
    #
    # Thus these two methods actually represent the first step in that
    # direction.  They also more honestly portray the situation.
    #
    def oidc_user_details(input)
      AuthnOidc::GetUserDetails.new.(
        request_body: input.request.body.read,
        service_id: input.service_id,
        conjur_account: input.account
      )
    end

    # NOTE: We can revisit this decision, but for now there is absolutely no
    # reason to be bound the `valid?(input)` interface for this "exceptional"
    # authenticator.
    #
    # Since we've already get to call `GetUserDetials` here for the username to
    # be used in `validate_security`, we don't want to recalculate it, so we
    # pass the result in.
    #
    def oidc_validate_credentials(input_with_username, user_details)
      AuthnOidc::Authenticator.new.(
        input: input_with_username,
        user_details: user_details
      )
    end

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
      raise InvalidOrigin unless authn_role.valid_origin?(input.origin)
    end

    def new_token(input)
      token_factory.signed_token(
        account: input.account,
        username: input.username
      )
    end

    def new_login(input, key)
      LoginResponse.new(
        role_id: role(input.username, input.account).id,
        authentication_key: key
      )
    end
  end

end

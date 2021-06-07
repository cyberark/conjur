require 'command_class'

module Authentication
  module AuthnJwt
    # Generic JWT authenticator that receive JWT vendor configuration and uses to validate that the authentication
    # request is valid, and return conjur authn token accordingly
    Authenticator = CommandClass.new(
      dependencies: {
        token_factory: TokenFactory.new,
        logger: Rails.logger,
        audit_log: ::Audit.logger,
        validate_origin: ::Authentication::ValidateOrigin.new,
        role_class: ::Role,
        webservice_class: ::Authentication::Webservice,
        validate_role_can_access_webservice: ::Authentication::Security::ValidateRoleCanAccessWebservice.new,
        role_id_class: Audit::Event::Authn::RoleId
      },
      inputs: %i[jwt_configuration authenticator_input]
    ) do
      extend(Forwardable)
      def_delegators(:@authenticator_input, :account, :username, :client_ip, :authenticator_name, :service_id)

      def call
        validate_and_decode_token
        get_jwt_identity
        validate_user_has_access_to_webservice
        validate_origin
        validate_restrictions
        audit_success
        new_token
      rescue => e
        audit_failure(e)
        raise e
      end

      private

      def validate_and_decode_token
        @logger.debug(LogMessages::Authentication::AuthnJwt::CallingValidateAndDecodeToken.new)
        @jwt_configuration.validate_and_decode_token
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidateAndDecodeTokenPassed.new)
      end

      def get_jwt_identity
        @logger.debug(LogMessages::Authentication::AuthnJwt::CallingGetJwtIdentity.new)
        jwt_identity
        @logger.debug(LogMessages::Authentication::AuthnJwt::GetJwtIdentityPassed.new)
        @logger.info(LogMessages::Authentication::AuthnJwt::FoundJwtIdentity.new(jwt_identity))
        @jwt_identity_initialized = true
      end

      def jwt_identity
        @jwt_identity ||= @jwt_configuration.jwt_identity
      end

      def validate_user_has_access_to_webservice
        @validate_role_can_access_webservice.(
          webservice: webservice,
          account: account,
          user_id: jwt_identity,
          privilege: PRIVILEGE_AUTHENTICATE
        )
      end

      def validate_origin
        @validate_origin.(
          account: account,
          username: jwt_identity,
          client_ip: client_ip
        )
      end

      def validate_restrictions
        @logger.debug(LogMessages::Authentication::AuthnJwt::CallingValidateRestrictions.new)
        @jwt_configuration.validate_restrictions
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidateRestrictionsPassed.new)
      end

      def audit_success
        @audit_log.log(
          ::Audit::Event::Authn::Authenticate.new(
            authenticator_name: authenticator_name,
            service: webservice,
            role_id: audit_role_id,
            client_ip: client_ip,
            success: true,
            error_message: nil
          )
        )
      end

      def audit_failure(err)
        @audit_log.log(
          ::Audit::Event::Authn::Authenticate.new(
            authenticator_name: authenticator_name,
            service: webservice,
            role_id: audit_role_id,
            client_ip: client_ip,
            success: false,
            error_message: err.message
          )
        )
      end

      def identity_role
        @role_class.by_login(
          jwt_identity,
          account: account
        )
      end

      # If there is no jwt identity so role and username are nil
      def audit_role_id
        role = identity_role if @jwt_identity_initialized
        username = jwt_identity if @jwt_identity_initialized
        @role_id_class.new(
          role: role,
          account: account,
          username: username
          ).to_s
      end

      def webservice
        @webservice ||= @webservice_class.new(
          account: account,
          authenticator_name: authenticator_name,
          service_id: service_id
        )
      end

      def new_token
        @logger.debug(LogMessages::Authentication::AuthnJwt::JwtAuthenticationPassed.new)
        @token_factory.signed_token(
          account: account,
          username: jwt_identity
        )
      end
    end
  end
end

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
      },
      inputs: %i[jwt_configuration authenticator_input]
    ) do
      extend(Forwardable)
      def_delegators(:@authenticator_input, :account, :username, :client_ip, :authenticator_name, :service_id)

      def call
        create_authentication_parameters
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

      def create_authentication_parameters
        authentication_parameters
      end

      def authentication_parameters
        @authentication_parameters ||= @jwt_configuration.authentication_parameters(@authenticator_input)
      end

      def validate_and_decode_token
        @logger.debug(LogMessages::Authentication::AuthnJwt::VALIDATE_AND_DECODE_TOKEN.new)
        @authentication_parameters.decoded_token = @jwt_configuration.validate_and_decode_token(@authentication_parameters)
      end

      def get_jwt_identity
        # Will be changed when real get identity implemented
        @logger.debug(LogMessages::Authentication::AuthnJwt::GET_JWT_IDENTITY.new)
        @authentication_parameters.jwt_identity =  @jwt_configuration.jwt_identity(@authentication_parameters)
      end

      def validate_user_has_access_to_webservice
        @validate_role_can_access_webservice.(
          webservice: webservice,
            account: account,
            user_id: @authentication_parameters.jwt_identity,
            privilege: PRIVILEGE_AUTHENTICATE
        )
      end

      def validate_origin
        @validate_origin.(
          account: account,
          username: @authentication_parameters.jwt_identity,
          client_ip: client_ip
        )
      end

      def validate_restrictions
        @logger.debug(LogMessages::Authentication::AuthnJwt::CALLING_VALIDATE_RESTRICTIONS.new)
        @jwt_configuration.validate_restrictions(@authentication_parameters)
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

      def role
        if @authentication_parameters and @authentication_parameters.jwt_identity
          return @role_class.by_login(
            @authentication_parameters.jwt_identity,
            account: account
          )
        end
        @role_class.by_login(
          "",
          account: account
        )
      end

      def audit_role_id
        ::Audit::Event::Authn::RoleId.new(
          role: role,
          account: account,
          username: @authentication_parameters.jwt_identity
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
        @logger.debug(LogMessages::Authentication::AuthnJwt::JWT_AUTHENTICATION_PASSED.new)
        @token_factory.signed_token(
          account: account,
          username: @authentication_parameters.jwt_identity
        )
      end
    end
  end
end

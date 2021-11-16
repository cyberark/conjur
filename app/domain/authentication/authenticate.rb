# frozen_string_literal: true

require 'command_class'

module Authentication

  Authenticate ||= CommandClass.new(
    dependencies: {
      token_factory: TokenFactory.new,
      validate_webservice_is_whitelisted: ::Authentication::Security::ValidateWebserviceIsWhitelisted.new,
      validate_role_can_access_webservice: ::Authentication::Security::ValidateRoleCanAccessWebservice.new,
      validate_origin: ::Authentication::ValidateOrigin.new,
    },
    inputs: %i[authenticator_input authenticators enabled_authenticators]
  ) do
    extend(Forwardable)
    def_delegators(
      :@authenticator_input, :authenticator_name, :account, :username,
      :webservice, :client_ip, :role
    )

    def call
      validate_authenticator_exists
      validate_webservice_is_whitelisted
      validate_user_has_access_to_webservice
      validate_origin
      validate_credentials
      new_token
    rescue => e
      raise e
    end

    private

    def authenticator
      @authenticator = @authenticators[authenticator_name]
    end

    def validate_authenticator_exists
      raise Errors::Authentication::AuthenticatorNotSupported, authenticator_name unless authenticator
    end

    def validate_credentials
      raise Errors::Authentication::InvalidCredentials unless authenticator.valid?(@authenticator_input)
    end

    def validate_webservice_is_whitelisted
      @validate_webservice_is_whitelisted.(
        webservice: webservice,
        account: account,
        enabled_authenticators: @enabled_authenticators
      )
    end

    def validate_user_has_access_to_webservice
      @validate_role_can_access_webservice.(
        webservice: webservice,
        account: account,
        user_id: username,
        privilege: 'authenticate'
      )
    end

    def validate_origin
      @validate_origin.(
        account: account,
        username: username,
        client_ip: client_ip
      )
    end

    def new_token
      @token_factory.signed_token(
        account: account,
        username: username
      )
    end
  end
end

class AuthenticatorNotEnabled < RuntimeError
  def initialize(authenticator_name)
    super("'#{authenticator_name}' not whitelisted in CONJUR_AUTHENTICATORS")
  end
end

class ServiceNotDefined < RuntimeError
  def initialize(service_name)
    super("Webservice '#{service_name}' is not defined in the Conjur policy")
  end
end

class NotAuthorizedInConjur < RuntimeError
  def initialize(user_id)
    super("User '#{user_id}' is not authorized in the Conjur policy")
  end
end

class AuthenticatorSecurity
  def initialize(authn_type:,
                 account:,
                 whitelisted_authenticators: ENV['CONJUR_AUTHENTICATORS'])
    @authn_type = authn_type
    @account = account
    @authenticators = authenticators_array(whitelisted_authenticators)

    validate_constructor_arguments
  end

  def validate(service_id, user_id)
    validate_nonempty('service_id', service_id)
    validate_nonempty('user_id', user_id)

    service_name = webservice_name(service_id)

    validate_service_whitelisted(service_name)
    validate_user_requirements(service_name, user_id)
  end

  private

  def validate_constructor_arguments
    validate_nonempty('authn_type', @authn_type)
    validate_nonempty('account', @account)
  end

  def authenticators_array(comma_delimited_authenticators)
    (comma_delimited_authenticators || '').split(',').map(&:strip)
  end

  def webservice_name(service_id)
    "#{@authn_type}/#{service_id}"
  end

  def validate_service_whitelisted(service_name)
    is_whitelisted = @authenticators.include?(service_name)
    raise AuthenticatorNotEnabled, service_name unless is_whitelisted
  end

  def validate_user_requirements(service_name, user_id)
    UserSecurityRequirements.new(
       user_id: user_id, 
       webservice_name: service_name,
       account: @account
    ).validate
  end

  def validate_nonempty(name, value)
    raise ArgumentError, "'#{name}' must not be empty" if value.to_s.empty?
  end

  class UserSecurityRequirements
    def initialize(user_id:,
                   webservice_name:,
                   account:)

      @user_id         = user_id
      @webservice_name = webservice_name
      @account  = account
    end

    def validate
      raise ServiceNotDefined, @webservice_name unless webservice
      raise NotAuthorizedInConjur, @user_id unless user_role
      raise NotAuthorizedInConjur, @user_id unless user_can_authenticate_to_webservice
    end

    private

    def user_role_id
      @user_role_id ||= Role.roleid_from_username(@account, @user_id)
    end

    def user_role
      @user_role ||= Role[user_role_id]
    end

    def webservice_id
      "#{@account}:webservice:conjur/#{@webservice_name}"
    end

    def webservice
      @webservice ||= Resource[webservice_id]
    end

    def user_can_authenticate_to_webservice
      user_role.allowed_to?("authenticate", webservice)
    end
  end
end

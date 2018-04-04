# Outstanding questions:
# 
#     1. Best way to enforce mapping to status codes
#     2. Should we do the enabled/defined checks when object is created?
#        Seems redundant that we retest it on every validation
# 
# Example use:
# 
# post '/authenticate/:user' do
#   begin
#     @security_requirements.validate          #initialized by web service
#     #specific auth code here
#   rescue AuthenticatorNotEnabled => e
#     # 1. map it to a status code  (TODO: answer Geri's question on this)
#     # 2. put the error message in whatever format we want (eg, json)
#   rescue ServiceNotDefined => e
#     # same
#   rescue NotAuthorizedInConjur => e
#     # same
#   end
# end

require 'conjur-api'

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

class AuthenticatorSecurityRequirements
  def initialize(authn_type:,
                 whitelisted_authenticators: ENV['CONJUR_AUTHENTICATORS'],
                 conjur_account: ENV['CONJUR_ACCOUNT'])
    @authn_type = authn_type
    @authenticators = authenticators_array(whitelisted_authenticators)
    @conjur_account = conjur_account

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
    validate_nonempty('whitelisted_authenticators', @authenticators)
    validate_nonempty('conjur_account', @conjur_account)
  end

  def authenticators_array(comma_delimited_authenticators)
    (comma_delimited_authenticators || '').split(',').map(&:strip)
  end

  def webservice_name(service_id)
    "authn-#{@authn_type}/#{service_id}"
  end

  def validate_service_whitelisted(service_name)
    raise AuthenticatorNotEnabled, service_name unless @authenticators.include?(service_name)
  end

  def validate_user_requirements(service_name, user_id)
    UserSecurityRequirements.new(
       user_id: user_id, 
       webservice_name: service_name,
       conjur_account: @conjur_account
    ).validate
  end

  def validate_nonempty(name, value)
    raise ArgumentError, "'#{name}' must not be empty" if value.empty?
  end

  class UserSecurityRequirements
    def initialize(user_id:,
                   webservice_name:,
                   conjur_account:)

      @user_id         = user_id
      @webservice_name = webservice_name
      @conjur_account  = conjur_account
      @conjur_api      = Conjur::API
    end

    def validate
      raise ServiceNotDefined, @webservice_name unless webservice.exists?
      raise NotAuthorizedInConjur, @user_id unless user_role.exists? 
      raise NotAuthorizedInConjur, @user_id unless webservice.permitted?("authenticate")
    end

    private

    def user_role
      @conjur_api.role_from_username(
        users_api_instance, @user_id, @conjur_account)
    end

    def users_api_instance
      @conjur_api.new_from_token(
        @conjur_api.authenticate_local(@user_id.to_s))  # do we need to_s?
    end

    def webservice
      users_api_instance.resource("#{@conjur_account}:webservice:conjur/#{@webservice_name}")
    end
  end
end

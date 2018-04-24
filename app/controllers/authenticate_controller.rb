class AuthenticateController < ApplicationController
  include TokenGenerator

  # prevents needless db queries
  #
  # TODO move into Security

  def authenticate

    # TODO move the Strategy into an initializer
    Authentication::Strategy.new.conjur_token(
      Authentication::Strategy::Input.new(
        authenticator_name: params[:authenticator],
        service_id:         params[:service_id],
        account:            params[:account],
        username:           params[:username],
        password:           request.body.read
      )
    )
  rescue
    # TODO placeholder for adding json error messages
    raise Unauthorized

    # TODO: change that param to params[:authn_type]
    authenticator = params[:authenticator]
    service_id    = params[:service_id]
    account       = params[:account]
    username      = params[:id]
    password      = request.body.read
    role_id       = MemoizedRole.roleid_from_username(account, username)

    validate_roleid_is_nonempty!(role_id)
    
    case authenticator
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

    # If we arrive here, the user is authenticated and `role` is set
    # Otherwise Unauthorized would have already been raised

    authentication_token = sign_token(role)
    render json: authentication_token
  end
  
  protected

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

  def validate_roleid_is_nonempty!(role_id)
    unless role_id
      logger.debug "Role #{role_id} not found"
      raise Unauthorized 
    end
  end

  def validate_credentials!(credentials, password)
    unless credentials
      logger.debug "Credentials not found"
      raise Unauthorized 
    end
    unless credentials.valid_api_key?(password)
      logger.debug "Invalid api_key"
      raise Unauthorized 
    end
  end

  def ldap_authenticator
    @ldap_authenticator ||= Authentication::Ldap::Authn.new(
      ldap_server: Authentication::Ldap::Server.new(
        uri:     ENV['LDAP_URI'],
        base:    ENV['LDAP_BASE'],
        bind_dn: ENV['LDAP_BINDDN'],
        bind_pw: ENV['LDAP_BINDPW']
      ),
      ldap_filter: ENV['LDAP_FILTER']
    )
  end

end

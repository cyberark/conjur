class AuthenticateController < ApplicationController
  include TokenGenerator

  def authenticate
    # authenticator = params[:authenticator]
    # service_id    = params[:service_id]
    account       = params[:account]
    username      = params[:id]
    password      = request.body.read
    role_id       = Role.roleid_from_username(account, username)

    validate_role_exists!(role_id)

    if ENV['CONJUR_AUTHENTICATORS'].match(/authn-ldap/)
      authenticator, service_id = ENV['CONJUR_AUTHENTICATORS'].split(',').find{|i| i.match(/authn-ldap/)}.split('/')
      validate_security!(authenticator, account, service_id, username)
      role = Role[role_id] if ldap_authenticator.valid?(username, password)
    else
      credentials = Credentials[role_id]
      validate_credentials!(credentials, password)
      role = credentials.role
    end

    #
    # case authenticator
    # when 'authn-ldap'
    #   validate_security!(authenticator, account, service_id, username)
    #   raise Unauthorized unless ldap_authenticator.valid?(username, password)
    #   role = Role[role_id]
    # # default conjur: authn
    # else
    #   credentials = Credentials[role_id]
    #   validate_credentials!(credentials, password)
    #   role = credentials.role
    # end

    # If we arrive here, the user is authenticated and `role` is set
    # Otherwise Unauthorized would have already been raised

    authentication_token = sign_token(role)
    render json: authentication_token
  end

  protected

  def validate_security!(authenticator, account, service_id, user_id)
    security = AuthenticatorSecurity.new(
      authn_type: authenticator, account: account) # TODO injuect Role, Resource
    security.validate(service_id, user_id)
  rescue AuthenticatorNotEnabled, ServiceNotDefined, NotAuthorizedInConjur => e
    logger.debug(e.message)
    raise Unauthorized
  rescue => e
    logger.debug("Unexpected AuthenticatorSecurity Error: #{e.message}")
    raise Unauthorized
  end

  def validate_role_exists!(role_id)
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
    @ldap_authenticator ||= Authenticators::Ldap::Authn.new(
      ldap_server: Authenticators::Ldap::Server.new(
        uri:     ENV['LDAP_URI'],
        base:    ENV['LDAP_BASE'],
        bind_dn: ENV['LDAP_BINDDN'],
        bind_pw: ENV['LDAP_BINDPW']
      ),
      ldap_filter: ENV['LDAP_FILTER']
    )
  end

end

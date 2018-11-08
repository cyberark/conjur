# frozen_string_literal: true

class AuthenticateController < ApplicationController
  include BasicAuthenticator

  def index
    authenticators = {
      # Installed authenticator plugins
      installed: installed_authenticators.keys.sort,

      # Authenticator webservices created in policy
      configured: configured_authenticators.sort,

      # Authenticators white-listed in CONJUR_AUTHENTICATORS
      enabled: enabled_authenticators.sort
    }

    render json: authenticators
  end

  def login
    result = perform_basic_authn
    raise Unauthorized, "Client not authenticated" unless authentication.authenticated?
    render text: result.authentication_key
  end

  def authenticate
    authn_token = authentication_strategy.conjur_token(
      ::Authentication::Strategy::Input.new(
        authenticator_name: params[:authenticator],
        service_id:         params[:service_id],
        account:            params[:account],
        username:           params[:id],
        password:           request.body.read,
        origin:             request.ip,
        request:            request
      )
    )
    render json: authn_token
  rescue => e
    handle_authentication_error(e)
  end

  # - Prepare ID Token request
  # - Get ID Token with code from OKTA (OpenID Provider)
  # - Validate ID Token
  # - Link user details to Conjur User
  # - Check user has permmisions
  # - Encrypt ID Token
  # Returns IDToken encrypted, Expiration Duration and Username
  def login_oidc
    oidc_encrypted_token = oidc_authentication_strategy.oidc_encrypted_token(
      ::Authentication::Strategy::Input.new(
        authenticator_name: 'authn-oidc',
        service_id:         params[:service_id],
        account:            params[:account],
        username:           nil,
        password:           nil, # TODO: Remove once we seperate oidc Strategy
        origin:             request.ip,
        request:            request
      )
    )
    render json: oidc_encrypted_token
  rescue => e
    handle_authentication_error(e)
  end

  # - Decrypt ID token
  # - Validate UD Token
  # - Check user permission
  # - Introspect ID Token
  # Returns Conjur access token
  def authenticate_oidc
    authentication_token = oidc_authentication_strategy.conjur_token_oidc(
      ::Authentication::Strategy::Input.new(
        authenticator_name: 'authn-oidc',
        service_id:         params[:service_id],
        account:            params[:account],
        username:           nil,
        password:           nil, # TODO: Remove once we seperate oidc Strategy
        origin:             request.ip,
        request:            request
      )
    )
    render json: authentication_token
  rescue => e
    handle_authentication_error(e)
  end

  def k8s_inject_client_cert
    # TODO: add this to initializer
    ::Authentication::AuthnK8s::InjectClientCert.new.(
      conjur_account: ENV['CONJUR_ACCOUNT'],
      service_id: params[:service_id],
      csr: request.body.read
    )
    head :ok
  rescue => e
    handle_authentication_error(e)
  end

  private

  def handle_authentication_error(err)
    logger.debug("Authentication Error: #{err.message}")
    err.backtrace.each do |line|
      logger.debug(line)
    end

    case err
    when Conjur::RequiredResourceMissing
    when Conjur::RequiredSecretMissing
    when Authentication::Security::ServiceNotDefined
    when Authentication::Security::NotWhitelisted
      raise Exceptions::NotImplemented, err.message
    else
      raise Unauthorized
    end
  end

  def authentication_strategy
    @authentication_strategy ||= ::Authentication::Strategy.new(
      authenticators: installed_authenticators,
      audit_log: ::Authentication::AuditLog,
      security: nil,
      env: ENV,
      role_cls: ::Role,
      token_factory: TokenFactory.new,
      oidc_client_class: ::Authentication::AuthnOidc::OidcClient
    )
  end

  def oidc_authentication_strategy
    @oidc_authentication_strategy ||= ::Authentication::Strategy.new(
      authenticators: installed_authenticators,
      audit_log: ::Authentication::AuditLog,
      security: nil,
      env: ENV,
      role_cls: ::Role,
      token_factory: OidcTokenFactory.new,
      oidc_client_class: ::Authentication::AuthnOidc::OidcClient
    )
  end

  def installed_authenticators
    @installed_authenticators ||= ::Authentication::InstalledAuthenticators.authenticators(ENV)
  end

  def configured_authenticators
    @configured_authenticators ||= ::Authentication::InstalledAuthenticators.configured_authenticators
  end

  def enabled_authenticators
    ::Authentication::InstalledAuthenticators.enabled_authenticators(ENV)
  end
end

# frozen_string_literal: true

class AuthenticateController < ApplicationController
  include Authenticators
  include BasicAuthenticator

  def index 
    authenticators = {
      # Installed authenticator plugins
      installed: installed_authenticators.keys.sort,

      # Authenticators that support user login
      login: installed_login_authenticators.keys.sort,
    
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
    authentication_token = ::Authentication::Strategy.new(
      authenticators: installed_authenticators,
      audit_log: ::Authentication::AuditLog,
      security: nil,
      env: ENV,
      role_cls: ::Role,
      token_factory: TokenFactory.new
    ).conjur_token(
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
    render json: authentication_token
  rescue => e
    logger.debug("Authentication Error: #{e.message}")
    e.backtrace.each do |line|
      logger.debug(line)
    end
    raise Unauthorized
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
    logger.debug("Authentication Error: #{e.message}")
    e.backtrace.each do |line|
      logger.debug(line)
    end
    raise Unauthorized
  end
end

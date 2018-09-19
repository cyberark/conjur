# frozen_string_literal: true

module BasicAuthenticator
  extend ActiveSupport::Concern
  include Authenticators
  
  included do
    include ActionController::HttpAuthentication::Basic::ControllerMethods
  end
  
  def perform_basic_authn
    # we need to check the auth method.
    # authenticate_with_http_basic doesn't do that and freaks out randomly.
    return unless request.authorization =~ /^Basic /

    authenticate_with_http_basic do |username, password|
      authenticator_login(username, password).tap do |response|
        authentication.authenticated_role = ::Role[response.role_id]
        authentication.basic_user = true
      end
    rescue ::Authentication::Strategy::InvalidCredentials, 
           ::Authentication::Strategy::InvalidOrigin,
           ::Authentication::Security::NotAuthorizedInConjur
      raise ApplicationController::Unauthorized
    end
  end

  protected

  def authenticator_login(username, password)
    authentication_strategy.login(login_input(username, password))
  end

  def authentication_strategy
    ::Authentication::Strategy.new(
      authenticators: installed_login_authenticators,
      audit_log: ::Authentication::AuditLog,
      security: nil,
      env: ENV,
      role_cls: ::Role,
      token_factory: TokenFactory.new
    )
  end

  def login_input(username, password)
    ::Authentication::Strategy::Input.new(
      authenticator_name: params[:authenticator],
      service_id:         params[:service_id],
      account:            params[:account],
      username:           username,
      password:           password,
      origin:             request.ip,
      request:            request
    )
  end
end

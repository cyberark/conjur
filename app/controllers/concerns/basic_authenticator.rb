# frozen_string_literal: true

module BasicAuthenticator
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Basic::ControllerMethods

  def perform_basic_authn
    # we need to check the auth method.
    # authenticate_with_http_basic doesn't do that and freaks out randomly.
    return unless request.authorization =~ /^Basic /

    authenticate_with_http_basic do |username, password|
      authenticator_login(username, password).tap do |response|
        authentication.authenticated_role = ::Role[response.role_id]
        authentication.basic_user         = true
      end
    rescue Errors::Authentication::InvalidCredentials
      raise ApplicationController::Unauthorized, "Invalid username or password"
    rescue Errors::Authentication::InvalidOrigin
      raise ApplicationController::Forbidden, "User is not authorized to login from the current origin"
    rescue Errors::Authentication::Security::RoleNotAuthorizedOnResource
      raise ApplicationController::Forbidden, "User is not authorized to login to Conjur"
    end
  end

  private

  def authenticator_login(username, password)
    ::Authentication::Login.new.(
      authenticator_input: login_input(username, password),
      authenticators: installed_login_authenticators,
      enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV)
    )
  end

  def login_input(username, password)
    ::Authentication::AuthenticatorInput.new(
      authenticator_name: params[:authenticator],
      service_id:         params[:service_id],
      account:            params[:account],
      username:           username,
      credentials:        password,
      client_ip:          request.ip,
      request:            request
    )
  end

  def installed_login_authenticators
    @installed_login_authenticators ||= ::Authentication::InstalledAuthenticators.login_authenticators(ENV)
  end
end

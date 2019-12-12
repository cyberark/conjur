# frozen_string_literal: true

class AuthenticateController < ApplicationController
  include BasicAuthenticator
  include AuthorizeResource

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

  def status
    Authentication::ValidateStatus.new.(
      authenticator_status_input: status_input
    )
    render json: { status: "ok" }
  rescue => e
    render status_failure_response(e)
  end

  def update
    # TODO: validate that params[:enabed] is actually a boolean value,
    # otherwise anything other than false or nil will eval to true
    body_params = Rack::Utils.parse_nested_query(request.body.read)

    enabled = body_params['enabled'] || false
    
    resource_id = ::Authentication::Webservice.new(
      account: params[:account],
      authenticator_name: params[:authenticator],
      service_id: params[:service_id]
    ).resource_id

    # TODO: return better error if resource doesn't exist
    
    authn_config = AuthenticatorConfig.where(resource_id: resource_id).first

    if authn_config.nil?
      authn_config = AuthenticatorConfig.create(
        resource_id: resource_id,
        enabled: enabled
      )
    else
      authn_config.update(enabled: enabled)
    end

    head :no_content
  end
  
  def status_input
    Authentication::AuthenticatorStatusInput.new(
      authenticator_name: params[:authenticator],
      service_id: params[:service_id],
      account: params[:account],
      username: ::Role.username_from_roleid(current_user.role_id)
    )
  end

  def login
    result = perform_basic_authn
    raise Unauthorized, "Client not authenticated" unless authentication.authenticated?
    render text: result.authentication_key
  end

  def authenticate
    authn_token = Authentication::Authenticate.new.(
      authenticator_input: authenticator_input,
        authenticators: installed_authenticators
    )
    render json: authn_token
  rescue => e
    handle_authentication_error(e)
  end

  def authenticator_input
    Authentication::AuthenticatorInput.new(
      authenticator_name: params[:authenticator],
      service_id: params[:service_id],
      account: params[:account],
      username: params[:id],
      password: request.body.read,
      origin: request.ip,
      request: request
    )
  end

  def authenticate_oidc
    authentication_token = Authentication::AuthnOidc::Authenticate.new.(
      authenticator_input: oidc_authenticator_input
    )
    render json: authentication_token
  rescue => e
    handle_authentication_error(e)
  end

  def oidc_authenticator_input
    Authentication::AuthenticatorInput.new(
      authenticator_name: 'authn-oidc',
      service_id: params[:service_id],
      account: params[:account],
      username: nil,
      password: nil,
      origin: request.ip,
      request: request
    )
  end

  def k8s_inject_client_cert
    # TODO: add this to initializer
    Authentication::AuthnK8s::InjectClientCert.new.(
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
    logger.debug("Authentication Error: #{err.inspect}")
    err.backtrace.each do |line|
      logger.debug(line)
    end

    case err
    when Errors::Authentication::Security::NotWhitelisted,
      Errors::Authentication::Security::ServiceNotDefined,
      Errors::Authentication::Security::UserNotDefinedInConjur,
      Errors::Authentication::Security::AccountNotDefined,
      Errors::Authentication::AuthnOidc::IdTokenFieldNotFoundOrEmpty,
      Errors::Authentication::AuthnOidc::IdTokenVerifyFailed,
      Errors::Authentication::AuthnOidc::IdTokenInvalidFormat,
      Errors::Conjur::RequiredSecretMissing,
      Errors::Conjur::RequiredResourceMissing
      raise Unauthorized

    when Errors::Authentication::Security::UserNotAuthorizedInConjur
      raise Forbidden

    when Errors::Authentication::RequestBody::MissingRequestParam
      raise BadRequest

    when Errors::Authentication::AuthnOidc::IdTokenExpired
      raise Unauthorized.new(err.message, true)

    when Errors::Authentication::AuthnOidc::ProviderDiscoveryTimeout
      raise GatewayTimeout

    when Errors::Util::ConcurrencyLimitReachedBeforeCacheInitialization
      raise ServiceUnavailable

    when Errors::Authentication::AuthnOidc::ProviderDiscoveryFailed,
      Errors::Authentication::AuthnOidc::ProviderFetchCertificateFailed
      raise BadGateway

    else
      raise Unauthorized
    end
  end

  def status_failure_response(error)
    payload = {
      status: "error",
      error: error.inspect
    }

    status_code = case error
                  when Errors::Authentication::Security::UserNotAuthorizedInConjur
                    :forbidden
                  when Errors::Authentication::StatusNotImplemented
                    :not_implemented

                  when Errors::Authentication::AuthenticatorNotFound
                    :not_found
                  else
                    :internal_server_error
                  end

    { :json => payload, :status => status_code }
  end

  def installed_authenticators
    @installed_authenticators ||= Authentication::InstalledAuthenticators.authenticators(ENV)
  end

  def configured_authenticators
    @configured_authenticators ||= Authentication::InstalledAuthenticators.configured_authenticators
  end

  def enabled_authenticators
    Authentication::InstalledAuthenticators.enabled_authenticators(ENV)
  end
end

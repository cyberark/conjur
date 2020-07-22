# frozen_string_literal: true

class AuthenticateController < ApplicationController
  include BasicAuthenticator
  include AuthorizeResource

  def index
    authenticators = {
      # Installed authenticator plugins
      installed: installed_authenticators.keys.sort,

      # Authenticator webservices created in policy
      configured:
        Authentication::InstalledAuthenticators.configured_authenticators.sort,

      # Authenticators white-listed in CONJUR_AUTHENTICATORS
      enabled: enabled_authenticators.sort
    }

    render json: authenticators
  end

  def status
    Authentication::ValidateStatus.new.(
      authenticator_status_input: status_input,
      enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV)
    )
    render json: { status: "ok" }
  rescue => e
    render status_failure_response(e)
  end

  def update_config
    body_params = Rack::Utils.parse_nested_query(request.body.read)

    Authentication::UpdateAuthenticatorConfig.new.(
      account: params[:account],
      authenticator_name: params[:authenticator],
      service_id: params[:service_id],
      username: ::Role.username_from_roleid(current_user.role_id),
      enabled: body_params['enabled'] || false
    )

    head :no_content
  rescue => e
    handle_authentication_error(e)
  end

  def status_input
    Authentication::AuthenticatorStatusInput.new(
      authenticator_name: params[:authenticator],
      service_id: params[:service_id],
      account: params[:account],
      username: ::Role.username_from_roleid(current_user.role_id),
      client_ip: request.ip
    )
  end

  def login
    result = perform_basic_authn
    raise Unauthorized, "Client not authenticated" unless authentication.authenticated?
    render plain: result.authentication_key
  rescue => e
    handle_login_error(e)
  end

  def authenticate(input = authenticator_input)
    authn_token = Authentication::Authenticate.new.(
      authenticator_input: input,
      authenticators: installed_authenticators,
      enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV)
    )
    render json: authn_token
  rescue => e
    handle_authentication_error(e)
  end

  def authenticator_input
    Authentication::AuthenticatorInput.new(
      authenticator_name: params[:authenticator],
      service_id:         params[:service_id],
      account:            params[:account],
      username:           params[:id],
      credentials:        request.body.read,
      client_ip:          request.ip,
      request:            request
    )
  end

  # Update the input to have the username from the token and authenticate
  def authenticate_oidc
    input = Authentication::AuthnOidc::UpdateInputWithUsernameFromIdToken.new.(
      authenticator_input: oidc_authenticator_input
    )
  rescue => e
    handle_authentication_error(e)
  else
    authenticate(input)
  end

  def oidc_authenticator_input
    Authentication::AuthenticatorInput.new(
      authenticator_name: 'authn-oidc',
      service_id:         params[:service_id],
      account:            params[:account],
      username:           nil,
      credentials:        request.body.read,
      client_ip:          request.ip,
      request:            request
    )
  end

  def k8s_inject_client_cert
    # TODO: add this to initializer
    Authentication::AuthnK8s::InjectClientCert.new.(
      conjur_account:   ENV['CONJUR_ACCOUNT'],
      service_id:       params[:service_id],
      client_ip:        request.ip,
      csr:              request.body.read,

      # The host-id is split in the client where the suffix is in the CSR
      # and the prefix is in the header. This is done to maintain backwards-compatibility
      host_id_prefix:   request.headers["Host-Id-Prefix"]
    )
    head :ok
  rescue => e
    handle_authentication_error(e)
  end

  private

  def handle_login_error(err)
    log_error(err, "Login")

    case err
    when Errors::Authentication::Security::AuthenticatorNotWhitelisted,
      Errors::Authentication::Security::WebserviceNotFound,
      Errors::Authentication::Security::AccountNotDefined,
      Errors::Authentication::Security::RoleNotFound
      raise Unauthorized
    else
      raise err
    end
  end

  def handle_authentication_error(err)
    log_error(err, "Authentication")

    case err
    when Errors::Authentication::Security::AuthenticatorNotWhitelisted,
      Errors::Authentication::Security::WebserviceNotFound,
      Errors::Authentication::Security::RoleNotFound,
      Errors::Authentication::Security::AccountNotDefined,
      Errors::Authentication::AuthnOidc::IdTokenFieldNotFoundOrEmpty,
      Errors::Authentication::Jwt::TokenVerificationFailed,
      Errors::Authentication::Jwt::TokenDecodeFailed,
      Errors::Conjur::RequiredSecretMissing,
      Errors::Conjur::RequiredResourceMissing
      raise Unauthorized

    when Errors::Authentication::Security::RoleNotAuthorizedOnResource
      raise Forbidden

    when Errors::Authentication::RequestBody::MissingRequestParam
      raise BadRequest

    when Errors::Authentication::Jwt::TokenExpired
      raise Unauthorized.new(err.message, true)

    when Errors::Authentication::OAuth::ProviderDiscoveryTimeout
      raise GatewayTimeout

    when Errors::Util::ConcurrencyLimitReachedBeforeCacheInitialization
      raise ServiceUnavailable

    when Errors::Authentication::OAuth::ProviderDiscoveryFailed,
      Errors::Authentication::OAuth::FetchProviderKeysFailed
      raise BadGateway

    when Errors::Authentication::AuthnK8s::CSRMissingCNEntry,
      Errors::Authentication::AuthnK8s::CertMissingCNEntry
      raise ArgumentError

    else
      raise Unauthorized
    end
  end

  def log_error(err, action)
    logger.info("#{action} Error: #{err.inspect}")
    err.backtrace.each do |line|
      logger.debug(line)
    end
  end

  def status_failure_response(error)
    logger.debug("Status check failed with error: #{error.inspect}")
    error.backtrace.each do |line|
      logger.debug(line)
    end

    payload = {
      status: "error",
      error: error.inspect
    }

    status_code = case error
                  when Errors::Authentication::Security::RoleNotAuthorizedOnResource
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

  def enabled_authenticators
    Authentication::InstalledAuthenticators.enabled_authenticators(ENV)
  end
end

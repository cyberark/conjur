# frozen_string_literal: true

class AuthenticateController < ApplicationController
  include BasicAuthenticator
  include AuthorizeResource

  def oidc_authenticate_code_redirect
    # TODO: need a mechanism for an authenticator strategy to define the required
    # params. This will likely need to be done via the Handler.
    params.permit!

    auth_token = Authentication::Handler::AuthenticationHandler.new(
      authenticator_type: params[:authenticator]
    ).call(
      parameters: params.to_hash.symbolize_keys,
      request_ip: request.ip
    )

    render_authn_token(auth_token)
  rescue => e
    log_backtrace(e)
    raise e
  end

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

    render(json: authenticators)
  end

  def status
    Authentication::ValidateStatus.new.(
      authenticator_status_input: status_input,
      enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str
    )
    log_audit_success(
      authn_params: status_input,
      audit_event_class: Audit::Event::Authn::ValidateStatus
    )
    render(json: { status: "ok" })
  rescue => e
    log_audit_failure(
      authn_params: status_input,
      audit_event_class: Audit::Event::Authn::ValidateStatus,
      error: e
    )
    log_backtrace(e)
    render(status_failure_response(e))
  end

  def status_input
    @status_input ||= Authentication::AuthenticatorStatusInput.new(
      authenticator_name: params[:authenticator],
      service_id: params[:service_id],
      account: params[:account],
      username: ::Role.username_from_roleid(current_user.role_id),
      client_ip: request.ip
    )
  end

  def authn_jwt_status
    params[:authenticator] = "authn-jwt"
    Authentication::AuthnJwt::ValidateStatus.new.call(
      authenticator_status_input: status_input,
      enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str
    )
    render(json: { status: "ok" })
  rescue => e
    log_backtrace(e)
    render(status_failure_response(e))
  end

  def update_config
    Authentication::UpdateAuthenticatorConfig.new.(
      update_config_input: update_config_input
    )
    log_audit_success(
      authn_params: update_config_input,
      audit_event_class: Audit::Event::Authn::UpdateAuthenticatorConfig
    )
    head(:no_content)
  rescue => e
    log_audit_failure(
      authn_params: update_config_input,
      audit_event_class: Audit::Event::Authn::UpdateAuthenticatorConfig,
      error: e
    )
    handle_authentication_error(e)
  end

  def update_config_input
    @update_config_input ||= Authentication::UpdateAuthenticatorConfigInput.new(
      account: params[:account],
      authenticator_name: params[:authenticator],
      service_id: params[:service_id],
      username: ::Role.username_from_roleid(current_user.role_id),
      enabled: Rack::Utils.parse_nested_query(request.body.read)['enabled'] || false,
      client_ip: request.ip
    )
  end

  def login
    result = perform_basic_authn
    raise Unauthorized, "Client not authenticated" unless authentication.authenticated?

    render(plain: result.authentication_key)
  rescue => e
    handle_login_error(e)
  end

  def authenticate_jwt
    params[:authenticator] = "authn-jwt"
    authn_token = Authentication::AuthnJwt::OrchestrateAuthentication.new.call(
      authenticator_input: authenticator_input_without_credentials,
      enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str
    )
    render_authn_token(authn_token)
  rescue => e
    # At this point authenticator_input.username is always empty (e.g. cucumber:user:USERNAME_MISSING)
    log_audit_failure(
      authn_params: authenticator_input,
      audit_event_class: Audit::Event::Authn::Authenticate,
      error: e
    )
    handle_authentication_error(e)
  end

  # Update the input to have the username from the token and authenticate
  def authenticate_oidc
    params[:authenticator] = "authn-oidc"
    input = Authentication::AuthnOidc::UpdateInputWithUsernameFromIdToken.new.(
      authenticator_input: authenticator_input
    )
    # We don't audit success here as the authentication process is not done
  rescue => e
    # At this point authenticator_input.username is always empty (e.g. cucumber:user:USERNAME_MISSING)
    log_audit_failure(
      authn_params: authenticator_input,
      audit_event_class: Audit::Event::Authn::Authenticate,
      error: e
    )
    handle_authentication_error(e)
  else
    authenticate(input)
  end
  def authenticate_gcp
    params[:authenticator] = "authn-gcp"
    input = Authentication::AuthnGcp::UpdateAuthenticatorInput.new.(
      authenticator_input: authenticator_input
    )
    # We don't audit success here as the authentication process is not done
  rescue => e
    # At this point authenticator_input.username is always empty (e.g. cucumber:user:USERNAME_MISSING)
    log_audit_failure(
      authn_params: authenticator_input,
      audit_event_class: Audit::Event::Authn::Authenticate,
      error: e
    )
    handle_authentication_error(e)
  else
    authenticate(input)
  end

  def authenticate(input = authenticator_input)
    authn_token = Authentication::Authenticate.new.(
      authenticator_input: input,
      authenticators: installed_authenticators,
      enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str
    )
    log_audit_success(
      authn_params: input,
      audit_event_class: Audit::Event::Authn::Authenticate
    )
    render_authn_token(authn_token)
  rescue => e
    log_audit_failure(
      authn_params: input,
      audit_event_class: Audit::Event::Authn::Authenticate,
      error: e
    )
    handle_authentication_error(e)
  end

  def authenticator_input
    @authenticator_input ||= Authentication::AuthenticatorInput.new(
      authenticator_name: params[:authenticator],
      service_id: params[:service_id],
      account: params[:account],
      username: params[:id],
      credentials: request.body.read,
      client_ip: request.ip,
      request: request
    )
  end

  # create authenticator input without reading the request body
  # request body can be relatively large
  # authenticator will read it after basic validation check
  def authenticator_input_without_credentials
    Authentication::AuthenticatorInput.new(
      authenticator_name: params[:authenticator],
      service_id: params[:service_id],
      account: params[:account],
      username: params[:id],
      credentials: nil,
      client_ip: request.ip,
      request: request
    )
  end

  def k8s_inject_client_cert
    # TODO: add this to initializer
    Authentication::AuthnK8s::InjectClientCert.new.(
      conjur_account: ENV['CONJUR_ACCOUNT'],
      service_id: params[:service_id],
      client_ip: request.ip,
      csr: request.body.read,

      # The host-id is split in the client where the suffix is in the CSR
      # and the prefix is in the header. This is done to maintain backwards-compatibility
      host_id_prefix: request.headers["Host-Id-Prefix"]
    )
    head(:accepted)
  rescue => e
    handle_authentication_error(e)
  end

  private

  def render_authn_token(authn_token)
    content_type = :json
    if encoded_response?
      logger.debug(LogMessages::Authentication::EncodedJWTResponse.new)
      content_type = :plain
      authn_token = ::Base64.strict_encode64(authn_token.to_json)
      response.set_header("Content-Encoding", "base64")
    end
    render(content_type => authn_token)
  end

  def log_audit_success(
    authn_params:,
    audit_event_class:
  )
    ::Authentication::LogAuditEvent.new.call(
      authentication_params: authn_params,
      audit_event_class: audit_event_class,
      error: nil
    )
  end

  def log_audit_failure(
    authn_params:,
    audit_event_class:,
    error:
  )
    ::Authentication::LogAuditEvent.new.call(
      authentication_params: authn_params,
      audit_event_class: audit_event_class,
      error: error
    )
  end

  def handle_login_error(err)
    login_error = LogMessages::Authentication::LoginError.new(err.inspect)
    logger.info(login_error)
    log_backtrace(err)

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
    authentication_error = LogMessages::Authentication::AuthenticationError.new(err.inspect)
    logger.error(authentication_error)
    log_backtrace(err)

    case err
    when Errors::Authentication::Security::RoleNotAuthorizedOnResource
      raise Forbidden

    when Errors::Conjur::RequestedResourceNotFound
      raise RecordNotFound.new(err.message)

    when Errors::Authentication::RequestBody::MissingRequestParam
      raise BadRequest

    when Errors::Conjur::RequestedResourceNotFound
      raise RecordNotFound.new(err.message)

    when Errors::Authentication::Jwt::TokenExpired
      raise Unauthorized.new(err.message, true)

    when Errors::Util::ConcurrencyLimitReachedBeforeCacheInitialization
      raise ServiceUnavailable

    when Errors::Authentication::AuthnK8s::CSRMissingCNEntry,
      Errors::Authentication::AuthnK8s::CertMissingCNEntry
      raise ArgumentError

    when Rack::OAuth2::Client::Error
      raise BadRequest

    else
      raise Unauthorized
    end
  end

  def status_failure_response(error)
    logger.debug("Status check failed with error: #{error.inspect}")

    payload = {
      status: "error",
      error: error.inspect
    }

    status_code =
      case error
      when Errors::Authentication::Security::RoleNotAuthorizedOnResource
        :forbidden
      when Errors::Authentication::StatusNotSupported
        :not_implemented
      when Errors::Authentication::AuthenticatorNotSupported
        :not_found
      else
        :internal_server_error
      end

    { json: payload, status: status_code }
  end

  def installed_authenticators
    @installed_authenticators ||= Authentication::InstalledAuthenticators.authenticators(ENV)
  end

  def enabled_authenticators
    Authentication::InstalledAuthenticators.enabled_authenticators
  end

  def encoded_response?
    return false unless request.accept_encoding

    encodings = request.accept_encoding.split(",")
    encodings.any? { |encoding| encoding.squish.casecmp?("base64") }
  end
end

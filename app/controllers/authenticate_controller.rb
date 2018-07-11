# frozen_string_literal: true

# NOTE: This is needed to make the introspection use by InstalledAuthenticators
#       work.  It cannot be placed in an initializer instead.  There may be a 
#       better place for it, but this works.
#
#       It's purpose it to load all the pluggable authenticator files into 
#       memory, so we can determine which authenticators are available
#
Dir[File.expand_path("../domain/authentication/**/*.rb", __dir__)].each do |f|
  require f
end

class AuthenticateController < ApplicationController

  AUTHN_RESOURCE_PREFIX = "conjur/authn-"

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
        origin:             request.ip
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
    ::Authentication::AuthnK8s::Authenticator.new(env: ENV).inject_client_cert(params, request)
    head :ok
  rescue => e
    logger.debug("Authentication Error: #{e.message}")
    e.backtrace.each do |line|
      logger.debug(line)
    end
    raise Unauthorized
  end

  private

  def installed_authenticators
    @installed_authenticators ||= ::Authentication::InstalledAuthenticators.new(ENV)
  end

  def configured_authenticators
    identifier = Sequel.function(:identifier, :resource_id)
    kind = Sequel.function(:kind, :resource_id)

    Resource
      .where(
        identifier.like("#{AUTHN_RESOURCE_PREFIX}%"), 
        kind => "webservice"
      )
      .select_map(identifier)
      .map { |id| id.sub /^conjur\//, "" }
      .push(Authentication::Strategy.default_authenticator_name)
  end

  def enabled_authenticators
    (ENV["CONJUR_AUTHENTICATORS"] || Authentication::Strategy.default_authenticator_name).split(",")
  end
end

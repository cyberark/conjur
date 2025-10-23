# frozen_string_literal: true

require 'English'

class SecretsController < RestController
  include FindResource
  include AuthorizeResource

  before_action :current_user

  def initialize(
    *args,
    feature_flags: Rails.application.config.feature_flags,
    **kwargs
  )
    super(*args, **kwargs)

    @feature_flags = feature_flags
  end

  def create
    authorize(:update)

    if @feature_flags.enabled?(:dynamic_secrets) && dynamic_secret?
      raise Exceptions::MethodNotAllowed,
            "adding a static secret to a dynamic secret variable is not allowed"
    end

    value = request.raw_post

    validate_public_key(value) if params[:kind] == 'public_key'

    raise ArgumentError, "'value' may not be empty" if value.blank?

    # Only create a new secret version if the value is changed
    unless resource.secret&.value == value
      Secret.create(resource_id: resource.id, value: value)
    end

    resource.enforce_secrets_version_limit

    head(:created)
  ensure
    update_info = error_info.merge(
      resource: resource,
      user: @current_user,
      client_ip: request.ip,
      operation: "update"
    )

    Audit.logger.log(
      Audit::Event::Update.new(**update_info)
    )
  end

  def show
    authorize(:execute)

    if @feature_flags.enabled?(:dynamic_secrets) && dynamic_secret?(resource)
      value = handle_dynamic_secret(resource)
      mime_type = 'application/json'
    else
      version = params[:version]

      unless (secret = resource.secret(version: version))
        raise Exceptions::RecordNotFound.new(
          resource.id,
          message: "Requested version does not exist"
        )
      end

      value = secret.value

      mime_type = \
        resource.annotation('conjur/mime_type') || 'application/octet-stream'
    end

    send_data(value, type: mime_type)
  rescue Exceptions::RecordNotFound
    raise Errors::Conjur::MissingSecretValue, resource_id
  ensure
    audit_fetch(resource_id, version: version)
  end

  def batch
    variables = Resource.where(resource_id: variable_ids).eager(:secrets).all

    # Verify permissions on all of the requested variables
    authorize_many(variables, :execute)

    # Ensure the number of dynamic secrets requested is not greater than the
    # number allowed in the configuration
    ensure_batch_dynamic_secrets_max(
      variables.count { |var| dynamic_secret?(var) }
    )

    # Ensure we found all of the requested variables
    unless variable_ids.count == variables.count
      raise Exceptions::RecordNotFound,
            variable_ids.find { |r| !variables.map(&:id).include?(r) }
    end

    secrets = variables.map do |variable|
      audit_fetch(variable.resource_id)
      [variable.resource_id, fetch_secret(variable)]
    end.to_h

    # Re-encode the secrets, if requested
    if String(request.headers['Accept-Encoding']).casecmp?('base64')
      response.set_header("Content-Encoding", "base64")
      secrets.transform_values! { |value| Base64.encode64(value) }
    end

    render(json: secrets)
  rescue JSON::GeneratorError
    raise Errors::Conjur::BadSecretEncoding, secrets
  rescue Encoding::UndefinedConversionError
    raise Errors::Conjur::BadSecretEncoding, secrets
  rescue Exceptions::RecordNotFound => e
    raise Errors::Conjur::MissingSecretValue, e.id
  end

  def fetch_secret(variable)
    if dynamic_secret?(variable)
      handle_dynamic_secret(variable)
    else
      get_secret_from_variable(variable)
    end
  end

  def ensure_batch_dynamic_secrets_max(num_dynamic_secrets)
    max_dynamic_secrets = conjur_config.dynamic_secrets_per_request_max
    return unless num_dynamic_secrets > max_dynamic_secrets

    raise ApplicationController::UnprocessableEntity,
          "Number of dynamic secrets requested exceeds the maximum " \
          "allowed in a single request (#{max_dynamic_secrets})"
  end

  def get_secret_from_variable(variable)
    secret = variable.last_secret
    raise Exceptions::RecordNotFound, variable.resource_id unless secret

    secret.value
  end

  def audit_fetch(resource_id, version: nil)
    fetch_info = error_info.merge(
      resource_id: resource_id,
      version: version,
      user: current_user,
      client_ip: request.ip,
      operation: "fetch"
    )

    Audit.logger.log(
      Audit::Event::Fetch.new(**fetch_info)
    )
  end

  def error_info
    return { success: true } unless $ERROR_INFO

    # If resource exists and is not visible, the error info will say it cannot be found.
    # That is still what we want to report to the client, but in the log we
    # want the more accurate message 'Forbidden'.
    {
      success: false,
      error_message: (resource_exists? && !resource_visible? ? 'Forbidden' : $ERROR_INFO.message)
    }
  end

  # NOTE: We're following REST/http semantics here by representing this as
  #       an "expirations" that you POST to you.  This may seem strange given
  #       that what we're doing is simply updating an attribute on a secret.
  #       But keep in mind this purely an implementation detail -- we could
  #       have implemented expirations in many ways.  We want to expose the
  #       concept of an "expiration" to the user.  And per standard rest,
  #       we do that with a resource, "expirations."  Expiring a variable
  #       is then a matter of POSTing to create a new "expiration" resource.
  #
  #       It is irrelevant that the server happens to implement this request
  #       by assigning nil to `expires_at`.
  #
  #       Unfortuneatly, to be consistent with our other routes, we're abusing
  #       query strings to represent what is in fact a new resource.  Ideally,
  #       we'd use a slash instead, but decided that consistency trumps
  #       correctness in this case.
  #
  def expire
    raise(ArgumentError, "Invalid secret kind: #{params[:kind]}") unless params[:kind] == 'variable'

    authorize(:update)
    Secret.update_expiration(resource.id, nil)
    head(:created)
  end

  private

  def validate_public_key(value)
    unless value.match?(/\Assh-(rsa|ed25519|ecdsa-[a-z0-9-]+) [A-Za-z0-9+\/=]+ ?.*\z/)
      raise ArgumentError, "Invalid public key format"
    end
  end

  def variable_ids
    return @variable_ids if @variable_ids

    @variable_ids = (params[:variable_ids] || '').split(',').compact
    # Checks that variable_ids is not empty and doesn't contain empty variable ids
    raise ArgumentError, 'variable_ids' if @variable_ids.empty? ||
      @variable_ids.count != @variable_ids.reject(&:empty?).count

    @variable_ids
  end

  def dynamic_secret?(resource_object = resource)
    resource_object.kind == "variable" &&
      resource_object.identifier.start_with?(Issuer::DYNAMIC_VARIABLE_PREFIX)
  end

  def handle_dynamic_secret(resource)
    variable_data = {}
    request_id = request.env['action_dispatch.request_id']

    # Filter the issuer related annotations and remove the prefix
    resource.annotations.each do |annotation|
      next unless annotation.name.start_with?(Issuer::DYNAMIC_ANNOTATION_PREFIX)

      issuer_param = annotation.name.to_s[Issuer::DYNAMIC_ANNOTATION_PREFIX.length..-1]
      variable_data[issuer_param] = annotation.value
    end

    issuer = Issuer.first(account: resource.account, issuer_id: variable_data["issuer"])

    # There shouldn't be a state where a variable belongs to an issuer that
    # doesn't exit, but we check it to be safe.
    unless issuer
      raise ApplicationController::UnprocessableEntity,
            "Issuer assigned to " \
            "#{resource.id} was not found"
    end

    logger.info(
      LogMessages::Secrets::DynamicSecretRequest.new(
        request_id,
        variable_data["issuer"],
        issuer.issuer_type,
        variable_data["method"]
      )
    )

    issuer_data = {
      max_ttl: issuer.max_ttl,
      data: JSON.parse(issuer.data)
    }

    Issuers::EphemeralEngines::ConjurDynamicEngineClient.new(
      logger: logger,
      request_id: request_id,
      http_client: ephemeral_secrets_service_http_client
    ).dynamic_secret(
      issuer.issuer_type,
      variable_data["method"],
      @current_user.role_id,
      issuer_data,
      variable_data
    )
  end

  def ephemeral_secrets_service_http_client
    service_address = Rails.application.config.try(
      :ephemeral_secrets_service_address
    )
    service_port = Rails.application.config.try(
      :ephemeral_secrets_service_port
    )

    if service_address.nil? || service_port.nil?
      raise ApplicationController::UnprocessableEntity,
            "No ephemeral secret engine configured for Conjur"
    end

    Net::HTTP.new(
      service_address,
      service_port
    )
  end
end

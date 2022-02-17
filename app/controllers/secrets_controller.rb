# frozen_string_literal: true

require 'English'

class SecretsController < RestController
  include FindResource
  include AuthorizeResource

  before_action :current_user

  def create
    authorize(:update)

    value = request.raw_post

    raise ArgumentError, "'value' may not be empty" if value.blank?

    Secret.create(resource_id: resource.id, value: value)
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
    version = params[:version]

    unless (secret = resource.secret(version: version))
      raise Exceptions::RecordNotFound.new(\
        resource.id, message: "Requested version does not exist"
      )
    end
    value = secret.value

    mime_type = \
      resource.annotation('conjur/mime_type') || 'application/octet-stream'

    send_data(value, type: mime_type)
  rescue Exceptions::RecordNotFound
    raise Errors::Conjur::MissingSecretValue, resource_id
  ensure
    audit_fetch(resource_id, version: version)
  end

  def batch
    variables = Resource.where(resource_id: variable_ids).eager(:secrets).all

    unless variable_ids.count == variables.count
      raise Exceptions::RecordNotFound,
            variable_ids.find { |r| !variables.map(&:id).include?(r) }
    end

    result = {}

    authorize_many(variables, :execute)

    variables.each do |variable|
      result[variable.resource_id] = get_secret_from_variable(variable)

      audit_fetch(variable.resource_id)
    end

    render(json: result)
  rescue JSON::GeneratorError
    raise Errors::Conjur::BadSecretEncoding, result
  rescue Encoding::UndefinedConversionError
    raise Errors::Conjur::BadSecretEncoding, result
  rescue Exceptions::RecordNotFound => e
    raise Errors::Conjur::MissingSecretValue, e.id
  end

  def get_secret_from_variable(variable)
    secret = variable.last_secret
    raise Exceptions::RecordNotFound, variable.resource_id unless secret

    secret_value = secret.value
    accepts_base64 = String(request.headers['Accept-Encoding']).casecmp?('base64')
    if accepts_base64
      response.set_header("Content-Encoding", "base64")
      Base64.encode64(secret_value)
    else
      secret_value
    end
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
    authorize(:update)
    Secret.update_expiration(resource.id, nil)
    head(:created)
  end

  private

  def variable_ids
    return @variable_ids if @variable_ids

    @variable_ids = (params[:variable_ids] || '').split(',').compact
    # Checks that variable_ids is not empty and doesn't contain empty variable ids
    raise ArgumentError, 'variable_ids' if @variable_ids.empty? ||
      @variable_ids.count != @variable_ids.reject(&:empty?).count

    @variable_ids
  end
end

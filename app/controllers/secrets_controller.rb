# frozen_string_literal: true

require 'English'

class SecretsController < RestController
  include FindResource
  include AuthorizeResource
  include FollowFetchPcloudSecrets

  before_action :current_user

  # Wrap the request in a transaction.
  def run_with_transaction(&block)
    if params[:action].downcase.starts_with?('show')
      yield
    else
      Sequel::Model.db.transaction(&block)
    end
  end

  def create
    Rails.logger.error("create secret 1")
    authorize(:update)
    raise Exceptions::MethodNotAllowed, "adding a static secret to a dynamic secret variable is not allowed" if dynamic_secret?
    value = request.raw_post
    raise ArgumentError, "'value' may not be empty" if value.blank?
    resource_id = params[:account] + ":" + params[:kind] + ":" + params[:identifier]
    valueInRedis = $redis.get(ENV['TENANT_ID'] + "::/secrets/" + resource_id)
    if (!(valueInRedis.nil?))
      $redis.setex(ENV['TENANT_ID'] + "::/secrets/" + resource_id, 900, value)
    end
    Rails.logger.error("create secret 2 resource_id = #{resource_id}, value = #{value}")

    Secret.create(resource_id: resource_id, value: value)
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
    Rails.logger.error("in show secret!!!")
    version = params[:version]
    resource_id = params[:account] + ":" + params[:kind] + ":" + params[:identifier]
    #
    # resourceFromCache = $redis.get(ENV['TENANT_ID'] + "/secrets/" + "resource/" + resource_id)
    # if (resourceFromCache.nil?)
    #   resourceObj = self.resource
    #   $redis.setex(ENV['TENANT_ID'] + "/secrets/" + "resource/" + resource_id, 900, resourceObj.as_json)
    #   Rails.logger.error("Reading from RDS")
    # else
    #   Rails.logger.error("Reading from redis")
    #   # resourceObj = Resource.create(resource_id: resourceFromCache["id"], owner_id: resourceFromCache["owner"])
    #   resourceObj = Resource.new()
    #   resourceObj.from_json!(resourceFromCache)
    #   #Rails.logger.error("Reading from redis")
    #    Rails.logger.error("redis resource id is: #{resourceObj.resource_id}")
    # end

    value = $redis.get(ENV['TENANT_ID'] + "::/secrets/" + resource_id)
    if !(value.nil?)
      Rails.logger.error("Reading from REDIS")
      resourceObj = Resource.new
      resourceObj.from_json!(value)
      if (resourceObj.resource_id.nil?)
        authorize(:execute)
      else
        authorize(:execute, resourceObj)
      end
      mime_type = $redis.get(ENV['TENANT_ID'] + "::/secrets/" + resource_id + "/mime_type")

    else
      authorize(:execute)
      Rails.logger.error("Reading from RDS")
      if dynamic_secret?
        value = handle_dynamic_secret
        mime_type = 'application/json'
      else
        unless (secret = resource.secret(version: version))
          raise Exceptions::RecordNotFound.new(\
            resource_id, message: "Requested version does not exist"
          )
        end
        value = secret.value
        mime_type = \
          resource.annotation('conjur/mime_type') || 'application/octet-stream'
      end
      puts "value is: #{resource.as_json}"
      $redis.setex(ENV['TENANT_ID'] + "::/secrets/" + resource_id, 900, value)
      $redis.setex(ENV['TENANT_ID'] + "::/secrets/" + resource_id + "/mime_type", 900, mime_type)
    end

    send_data(value, type: mime_type)
  rescue Exceptions::RecordNotFound
    raise Errors::Conjur::MissingSecretValue, resource_id
  ensure
    audit_fetch(resource_id, version: version)
  end

  def batch
    #check if there is id that repeats itself
    check_input_correct

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
      secret_value.force_encoding('UTF-8')
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

  def check_input_correct
    unique_variables = variable_ids.uniq
    unless variable_ids.count == unique_variables.count
      duplicate_ids = variable_ids.find_all { |e| variable_ids.count(e) > 1 }.uniq
      raise Errors::Conjur::DuplicateVariable, duplicate_ids.join(",")
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

  def dynamic_secret?
    resource.kind == "variable" && resource.identifier.start_with?(Issuer::DYNAMIC_VARIABLE_PREFIX)
  end

  def handle_dynamic_secret
    account = params[:account]
    resource_annotations = resource.annotations
    variable_data = {}
    request_id = request.env['action_dispatch.request_id']

    # Filter the issuer related annotations and remove the prefix
    resource_annotations.each do |annotation|
      next unless annotation.name.start_with?(Issuer::DYNAMIC_ANNOTATION_PREFIX)
      issuer_param = annotation.name.to_s[Issuer::DYNAMIC_ANNOTATION_PREFIX.length..-1]
      variable_data[issuer_param] = annotation.value
    end

    issuer = Issuer.first(account: account, issuer_id: variable_data["issuer"])

    # There shouldn't be a state where a variable belongs to an issuer that doesn't exit, but we check it to be safe
    raise ApplicationController::InternalServerError, "Issuer assigned to #{account}:#{params[:kind]}:#{params[:identifier]} was not found" unless issuer

    logger.info(LogMessages::Secrets::DynamicSecretRequest.new(request_id, variable_data["issuer"], issuer.issuer_type, variable_data["method"]))

    issuer_data = {
      max_ttl: issuer.max_ttl,
      data: JSON.parse(issuer.data)
    }

    ConjurDynamicEngineClient.new(logger: logger, request_id: request_id)
                               .get_dynamic_secret(issuer.issuer_type, variable_data["method"], @current_user.role_id, issuer_data, variable_data)
  end
end

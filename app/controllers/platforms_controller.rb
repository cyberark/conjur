# frozen_string_literal: true

require_relative '../controllers/wrappers/policy_wrapper'
require_relative '../controllers/wrappers/policy_audit'
require_relative '../controllers/wrappers/templates_renderer'
require_relative '../domain/platforms/platform_types/platform_type_factory'
#
class PlatformsController < RestController
  include AuthorizeResource
  include PolicyAudit
  include PolicyWrapper
  include PolicyTemplates::TemplatesRenderer
  include BodyParser
  include FindPlatformResource

  before_action :current_user
  before_action :find_or_create_root_policy

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  PLATFORM_NOT_FOUND = "Platform not found"

  def create
    logger.info(LogMessages::Endpoints::EndpointRequested.new("POST platforms/#{params[:account]}"))
    action = :create
    authorize(action, resource)
    
    platform_type = PlatformTypeFactory.new.create_platform_type(params[:type])
    platform_type.validate(params)

    policy_fields = input_create_yaml(params[:id], platform_type.default_secret_method)
    create_platform_policy(policy_fields)

    save_platform(params)
    platform = get_platform_from_db(params[:account], params[:id])
    raise ApplicationController::InternalServerError, "There was an error saving the platform" unless platform
    platform_audit_success(platform.account, platform.platform_id, "create")

    render(json: platform.as_json, status: :created)
    
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("POST platforms/#{params[:account]}"))
  rescue Exceptions::RecordNotFound => e
    logger.error(LogMessages::Platforms::PlatformEndpointForbidden.new("create"))
    audit_failure(e, action)
    platform_audit_failure(params[:account], params[:id], "create", e.message)
    raise Exceptions::Forbidden, "platforms"
  rescue ApplicationController::BadRequest => e
    logger.error("Input validation error for platform [#{params[:id]}]: #{e.message}")
    audit_failure(e, action)
    render(json: {
             error: {
               code: "bad_request",
               message: e.message
             }
           }, status: :bad_request)
  rescue Sequel::UniqueConstraintViolation => e
    logger.error("Platform [#{params[:id]}] already exists")
    audit_failure(e, action)
    platform_audit_failure(params[:account], params[:id], "create", e.message)
    raise Exceptions::RecordExists.new("platform", params[:id])
  rescue => e
    audit_failure(e, action)
    platform_audit_failure(params[:account], params[:id], "create", e.message)
    head :internal_server_error
  end

  def delete
    logger.info(LogMessages::Endpoints::EndpointRequested.new("DELETE platforms/#{params[:account]}/#{params[:identifier]}"))
    action = :update
    authorize(action, resource)

    platform = get_platform_from_db(params[:account], params[:identifier])
    if platform
      policy_fields = input_delete_yaml(params[:identifier])
      delete_platform_policy(policy_fields)
      platform_audit_success(platform.account, platform.platform_id, "delete")
      # Deleting the platform causes a cascade delete of the record in the platforms table as well
      head :ok
    else
      raise Exceptions::RecordNotFound.new(params[:identifier], message: PLATFORM_NOT_FOUND)
    end

    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("DELETE platforms/#{params[:account]}/#{params[:identifier]}"))
  rescue Exceptions::RecordNotFound => e
    logger.error(LogMessages::Platforms::PlatformPolicyNotFound.new(resource_id))
    audit_failure(e, action)
    platform_audit_failure(params[:account], params[:identifier], "delete", e.message)
    raise Exceptions::RecordNotFound.new(params[:identifier], message: PLATFORM_NOT_FOUND)
  rescue => e
    audit_failure(e, action)
    platform_audit_failure(params[:account], params[:identifier], "delete", e.message)
    raise e
  end

  def get
    logger.info(LogMessages::Endpoints::EndpointRequested.new("GET platforms/#{params[:account]}/#{params[:identifier]}"))
    # If I can update the platform policy, it means I am allowed to view it as well
    action = :update
    authorize(action, resource)

    platform = get_platform_from_db(params[:account], params[:identifier])
    if platform
      platform_audit_success(platform.account, platform.platform_id, "get")
      render(json: platform.as_json, status: :ok)
    else
      # platform_audit_failure(platform.account, platform.platform_id, "get", PLATFORM_NOT_FOUND)
      raise Exceptions::RecordNotFound.new(params[:identifier], message: PLATFORM_NOT_FOUND)
    end

    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET platforms/#{params[:account]}/#{params[:identifier]}"))
  rescue Exceptions::RecordNotFound => e
    platform_audit_failure(params[:account], params[:identifier], "get", PLATFORM_NOT_FOUND)
    logger.error(LogMessages::Platforms::PlatformPolicyNotFound.new(resource_id))
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET platforms/#{params[:account]}/#{params[:identifier]}"))
    raise Exceptions::RecordNotFound.new(params[:identifier], message: PLATFORM_NOT_FOUND)
  rescue => e
    platform_audit_failure(params[:account], params[:identifier], "get", e.message)
    raise e
  end

  def list
    logger.info(LogMessages::Endpoints::EndpointRequested.new("GET platforms/#{params[:account]}"))
    # If I can update the platform policy, it means I am allowed to view it as well
    action = :update
    authorize(action, resource)

    platforms = list_platforms_from_db(params[:account])
    result = []
    platforms.each do |item|
      result.push(item.as_json)
    end
    platform_audit_success(params[:account], "*", "list")
    render(json: { platforms: result }, status: :ok)

    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET platforms/#{params[:account]}"))
  rescue Exceptions::RecordNotFound => e
    logger.error(LogMessages::Platforms::PlatformEndpointForbidden.new("list"))
    platform_audit_failure(params[:account], "*", "list", e.message)
    raise Exceptions::Forbidden, "platforms"
  rescue => e
    platform_audit_failure(params[:account], "*", "list", e.message)
    raise e
  end
end

private

def create_platform_policy(policy_fields)
  result_yaml = renderer(PolicyTemplates::CreatePlatform.new(), policy_fields)
  set_raw_policy(result_yaml)
  result = load_policy(Loader::CreatePolicy, false, resource)
  policy = result[:policy]
  audit_success(policy)
end

def delete_platform_policy(policy_fields)
  result_yaml = renderer(PolicyTemplates::DeletePlatform.new(), policy_fields)
  set_raw_policy(result_yaml)
  result = load_policy(Loader::ModifyPolicy, true, resource)
  policy = result[:policy]
  audit_success(policy)
end

def save_platform(request_input)
  platform = Platform.new(platform_id: request_input[:id], account: request_input[:account],
                          platform_type: request_input[:type],
                          max_ttl: request_input[:max_ttl], data: request_input[:data].to_json,
                          modified_at: Sequel::CURRENT_TIMESTAMP,
                          policy_id: "#{request_input[:account]}:policy:data/platforms/#{request_input[:id]}")
  platform.save
end

def get_platform_from_db(account, platform_id)
  Platform.where(account: account, platform_id: platform_id).first
end

def list_platforms_from_db(account)
  Platform.where(account: account).all
end

def input_create_yaml(platform_id, secret_method)
  return input = {
    "id" => platform_id,
    "default_secret_method" => secret_method
  }
end

def input_delete_yaml(platform_id)
  return input = {
    "id" => platform_id
  }
end

def platform_audit_success(account, platform_id, operation)
  subject = { account: account, platform: platform_id }
  Audit.logger.log(
    Audit::Event::Platform.new(
      user_id: current_user.role_id,
      client_ip: request.ip,
      subject: subject,
      message_id: "platform",
      success: true,
      operation: operation
    )
  )
end

def platform_audit_failure(account, platform_id, operation, error_message)
  subject = { account: account, platform: platform_id }
  Audit.logger.log(
    Audit::Event::Platform.new(
      user_id: current_user.role_id,
      client_ip: request.ip,
      subject: subject,
      message_id: "platform",
      success: false,
      operation: operation,
      error_message: error_message
    )
  )
end

# frozen_string_literal: true
require_relative '../controllers/wrappers/policy_wrapper'
require_relative '../controllers/wrappers/policy_audit'
# 
class WorkloadController < RestController
  include AuthorizeResource
  include BodyParser
  include FindPolicyResource
  include PolicyAudit
  include PolicyWrapper
  include ParamsValidator

  before_action :current_user
  before_action :find_or_create_root_policy

  set_default_content_type_for_path(%r{^/hosts}, 'application/json')

  def post
    logger.info(LogMessages::Endpoints::EndpointRequested.new("hosts/:account/*identifier"))
    action = :create
    params.permit(:identifier, :account, :id, :annotations, :safes)
          .to_h.symbolize_keys
    authorize(action, resource(params[:identifier]))
    validateId(params[:id])
    hostId = "#{params[:account]}:host:#{build_host_name_without_slash(params[:id], params[:identifier])}"
    hostResource = Resource.find(resource_id: hostId)
    if !hostResource.nil?
      raise Exceptions::RecordExists.new("host", hostId)
    end
    input = input_workload_create(params)
    result = submit_policy(Loader::CreatePolicy, PolicyTemplates::CreateHost.new(), input, resource(params[:identifier]))
    hostPolicy = result[:policy]
    grantPolicies = grantHostToSafes(params)
    audit_success(hostPolicy)
    grantPolicies.each do |policy|
      audit_success(policy)
    end
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("hosts/:account/*identifier"))
    render(json: {
      created_roles: result[:created_roles]
    }, status: :created)
  rescue => e
    audit_failure(e, action)
    raise e
  end

  def create
    logger.info(LogMessages::Endpoints::EndpointRequested.new("Create Host"))
    action = :create
    params.permit(:host_id, :account, :policy_tree, :annotations, :auth_apikey)
          .to_h.symbolize_keys
    policy_tree = params[:policy_tree]
    host_id = params[:host_id]
    # check there is permission on the policy tree
    authorize(action, resource(policy_tree))
    # validate host id
    validateId(host_id)
    # validate host doesn't exist
    full_host_id = "#{params[:account]}:host:#{build_host_name_without_slash(host_id, policy_tree)}"
    host_resource = Resource.find(resource_id: full_host_id)
    unless host_resource.nil?
      raise Exceptions::RecordExists.new("host", full_host_id)
    end
    # build policy json
    annotations = build_annotations(params)
    input = build_workload_policy(params, annotations)
    # submit policy
    result = submit_policy(Loader::CreatePolicy, PolicyTemplates::CreateHost.new(), input, resource(policy_tree))
    host_policy = result[:policy]
    audit_success(host_policy)
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("Create Host"))
    render_response(full_host_id, host_id, policy_tree, result)
  rescue => e
    audit_failure(e, action)
    if e.instance_of?(Forbidden)
      #when accessing restricted resources we should always return the code 404 (not found) and never 403 (forbidden) in order to avoid resource enumeration
      raise RecordNotFound.new(e.message)
    else
      raise e
    end
  end
end

private

def validateId(name)
  validate_params({"id" => name}, ->(k,v){
    !v.nil? && !v.empty? &&
      v.match?(/^[a-zA-Z0-9_-]+$/) && string_length_validator(3, 60).call(k, v)
  })
end

def input_workload_create(json_body)
  {
    "id" => json_body[:id],
    "annotations" => json_body[:annotations],
  }
end

def input_grant_safe(host_id)
  {
    "id" => host_id,
  }
end

def build_host_name(params)
  path = []
  path << params[:identifier] unless params[:identifier] == "root"
  path << params[:id]
  "/" + path.join('/')
end


def build_host_name_without_slash(host_id, policy_tree)
  path = []
  path << policy_tree unless policy_tree == "root"
  path << host_id
  path.join('/')
end

def grantHostToSafes(params)
  safes = params[:safes]
  policies = []
  if safes.nil?
    return policies
  end
  if !safes.is_a?(Array)
    raise ApplicationController::UnprocessableEntity, "safes must be an array."
  end
  action = :update
  host_id = build_host_name(params)
  safes.each do |safe|
    authorize(action, resource(safe))
    input = input_grant_safe(host_id)
    result = submit_policy(Loader::CreatePolicy, PolicyTemplates::GrantHostSafe.new(), input, resource(safe))
    policies << result[:policy]
  end
  return policies
end

def render_response(full_host_id, host_id, policy_tree, result)
  unless params[:auth_apikey].nil?
    render(json: {
      host_id: host_id,
      policy_tree: policy_tree,
      annotations: params[:annotations],
      api_key: result[:created_roles][full_host_id][:api_key]
    }, status: :created)
  else
    render(json: {
      host_id: host_id,
      policy_tree: policy_tree,
      annotations: params[:annotations],
    }, status: :created)
  end
end

def build_annotations(params)
  annotations = params[:annotations]
  # Add api key annotation if needed
  unless params[:auth_apikey].nil?
    annotations["authn/api-key"] = params[:auth_apikey]
  end
  annotations
end

def build_workload_policy(json_body, annotations)
  {
    "id" => json_body[:host_id],
    "annotations" => annotations
  }
end

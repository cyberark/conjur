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
    hostId = "#{params[:account]}:host:#{build_host_name_without_slash(params)}"
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
end

private

def validateId(id)
  if id.nil? || id.empty?
    raise ApplicationController::UnprocessableEntity, "id param is missing in body, must not be blank."
  end
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


def build_host_name_without_slash(params)
  path = []
  path << params[:identifier] unless params[:identifier] == "root"
  path << params[:id]
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

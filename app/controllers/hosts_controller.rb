# frozen_string_literal: true
require_relative '../controllers/wrappers/policy_wrapper'
require_relative '../controllers/wrappers/policy_audit'
# 
class HostsController < RestController
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
    authorize(action, resource)
    params.permit(:identifier, :account, :id, :annotations, :groups, :layers)
          .to_h.symbolize_keys
    validateId(params[:id])
    input = input_post_yaml(params)
    result = submit_policy(Loader::CreatePolicy, PolicyTemplates::CreateHost.new(), input)
    policy = result[:policy]
    audit_success(policy)
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

def input_post_yaml(json_body)
  {
    "id" => json_body[:id],
    "annotations" => json_body[:annotations],
    "groups" => json_body[:groups],
    "layers" => json_body[:layers]
  }
end

# frozen_string_literal: true
require_relative '../controllers/wrappers/policy_wrapper'
require_relative '../controllers/wrappers/policy_audit'
require_relative '../controllers/wrappers/templates_renderer'
# 
class HostsController < RestController
  include AuthorizeResource
  include PolicyAudit
  include PolicyWrapper
  include PolicyTemplates::TemplatesRenderer
  include BodyParser
  include FindPolicyResource

  before_action :current_user
  before_action :find_or_create_root_policy

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  set_default_content_type_for_path(%r{^/hosts}, 'application/json')

  def post
    logger.info(LogMessages::Endpoints::EndpointRequested.new("hosts/:account/*identifier"))
    action = :create
    authorize(action, resource)
    params.permit(:identifier, :account, :id, :annotations, :groups, :layers)
          .to_h.symbolize_keys
    validateId(params[:id])
    input = input_post_yaml(params)
    result_yaml = renderer(PolicyTemplates::CreateHost.new(), input)
    set_raw_policy(result_yaml)
    result = load_policy(Loader::CreatePolicy, false)
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
  return input = {
    "id" => json_body[:id],
    "annotations" => json_body[:annotations],
    "groups" => json_body[:groups],
    "layers" => json_body[:layers]
  }
end

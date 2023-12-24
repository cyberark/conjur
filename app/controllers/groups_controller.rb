# frozen_string_literal: true
require_relative '../controllers/wrappers/policy_wrapper'
require_relative '../controllers/wrappers/policy_audit'
require './app/domain/util/static_account'

class GroupsController < RestController
  include AuthorizeResource
  include BodyParser
  include FindPolicyResource
  include PolicyAudit
  include PolicyWrapper
  include ParamsValidator

  before_action :current_user
  before_action :find_or_create_root_policy

  set_default_content_type_for_path(%r{^/groups}, 'application/json')
  def add_member
    log_message = "Add member #{params[:kind]}:#{params[:id]} to group #{params[:identifier]}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))
    action = :update
    account = StaticAccount.account # Get the static account for api without account in path

    # validate all input is correct
    group_member_type = GroupMemberType.new
    group_member_type.validate(params, account)

    # Extract the group name and the branch from the identifier
    permitted_params = params.permit(:identifier, :kind, :id).to_h.symbolize_keys
    identifier = permitted_params[:identifier]
    group_name = group_member_type.get_group_name(identifier)
    branch = group_member_type.get_branch(identifier)
    member_kind = permitted_params[:kind]
    member_id = permitted_params[:id]

    # Validate there is permissions for current user to run update on the branch
    authorize(action, resource(branch))

    # build policy input
    input = build_add_member_to_group_policy_input(group_name, member_kind, member_id)
    # upload policy
    result = submit_policy(Loader::CreatePolicy, PolicyTemplates::AddMemberToGroup.new(), input, resource(branch))

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    render(json: {
      kind: permitted_params[:kind],
      id: permitted_params[:id]
    }, status: :created)
    audit_success(result[:policy])
  rescue => e
    audit_failure(e, action)
    raise e
  end

  private

  def build_add_member_to_group_policy_input(group_name, member_kind, member_id)
    {
      "id" => group_name,
      "kind" => member_kind,
      "member_id" => member_id
    }
  end

end
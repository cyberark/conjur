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
    log_message = "Add member #{params[:kind]}:#{params[:id]} to group #{params[:branch]}/#{params[:group_name]}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))
    action = :update
    account = StaticAccount.account # Get the static account for api without account in path

    # Extract the group name and the branch from the identifier
    permitted_params = params.permit(:branch, :group_name, :kind, :id).to_h.symbolize_keys
    branch = GroupMemberType.get_branch(permitted_params)
    group_name = permitted_params[:group_name]
    member_kind = permitted_params[:kind]
    member_id = permitted_params[:id]

    # validate all input is correct
    validate_add_member(params, account, branch, group_name, member_kind, member_id)

    # Validate there is permissions for current user to run update on the branch
    authorize(action, resource(branch))

    # build policy input
    input = build_add_member_to_group_policy_input(group_name, member_kind, member_id)
    # upload policy
    result = submit_policy(Loader::CreatePolicy, PolicyTemplates::AddMemberToGroup.new(), input, resource(branch))

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    render(json: {
      kind: member_kind,
      id: member_id
    }, status: :created)
    audit_success(result[:policy])
  rescue => e
    audit_failure(e, action)
    raise e
  end

  def remove_member
    log_message = "Remove member #{params[:kind]}:#{params[:resource]} from group #{params[:branch]}/#{params[:group_name]}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))
    action = :update
    account = StaticAccount.account # Get the static account for api without account in path

    group_member_type = GroupMemberType.new
    permitted_params = params.permit(:branch, :group_name, :kind, :resource).to_h.symbolize_keys
    group_name = permitted_params[:group_name]
    branch = permitted_params[:branch]
    member_kind = permitted_params[:kind]
    member_id = permitted_params[:resource]

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    head(204)
  end

  private

  def validate_add_member(params, account, branch, group_name, member_kind, member_id)
    group_id = GroupMemberType.get_group_id(account, branch, group_name)
    # Validate body is valid
    GroupMemberType.validate_input(params)
    # Validate member kind is supported
    GroupMemberType.verify_kind(member_kind)
    # Validate group is not identity users groups
    GroupMemberType.verify_group_allowed(group_name)
    # Validate group exists
    GroupMemberType.group_exists_validation(group_id)
    # Validate resource is not already a member
    GroupMemberType.verify_resource_is_not_member(group_id, member_kind, member_id)
  end

  def validate_remove_member(account, branch, group_name, kind, group_member_type)
    group_id = "#{account}:group:#{branch}/#{group_name}"
    # Validate member kind is supported
    group_member_type.verify_kind(kind)
    # Validate group is not identity users groups
    group_member_type.verify_group_allowed(group_name)
    # Validate group exists
    group_member_type.group_exists_validation(group_id)
  end

  def build_add_member_to_group_policy_input(group_name, member_kind, member_id)
    {
      "id" => group_name,
      "kind" => member_kind,
      "member_id" => member_id
    }
  end

end
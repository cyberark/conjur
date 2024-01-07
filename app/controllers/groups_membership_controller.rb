# frozen_string_literal: true
require_relative '../controllers/wrappers/policy_wrapper'
require_relative '../controllers/wrappers/policy_audit'
require './app/domain/util/static_account'

class GroupsMembershipController < V2RestController
  include AuthorizeResource
  include BodyParser
  include FindPolicyResource
  include PolicyAudit
  include PolicyWrapper
  include GroupMembershipValidator
  include APIValidator

  before_action :current_user
  before_action :find_or_create_root_policy

  NUM_OF_ADD_DATA_PARAMS = 7
  NUM_OF_REMOVE_DATA_PARAMS = 6

  def add_member
    log_message = "Add member #{params[:kind]}:#{params[:id]} to group #{params[:branch]}/#{params[:group_name]}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))
    action = :update

    # Extract the group name and the branch from the identifier
    permitted_params = params.permit(:branch, :group_name, :kind, :id).to_h.symbolize_keys
    branch = GroupMemberType.get_branch(permitted_params)
    group_name = permitted_params[:group_name]
    member_kind = permitted_params[:kind]
    member_id = permitted_params[:id]

    # validate all input is correct
    validate_add_member_input(action, branch, group_name, member_id, member_kind, branch)

    # build policy input
    input = build_member_to_group_policy_input(group_name, member_kind, member_id)
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
    log_message = "Remove member #{params[:kind]}:#{params[:id]} from group #{params[:branch]}/#{params[:group_name]}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))
    action = :update

    # Extract the group name and the branch from the identifier
    permitted_params = params.permit(:branch, :group_name, :kind, :id).to_h.symbolize_keys
    branch = GroupMemberType.get_branch(permitted_params)
    group_name = permitted_params[:group_name]
    member_kind = permitted_params[:kind]
    member_id = permitted_params[:id]

    # validate all input is correct
    validate_remove_member_input(action, branch, group_name, member_id, member_kind, branch)

    # build policy input
    input = build_member_to_group_policy_input(group_name, member_kind, member_id)
    # upload policy
    result = submit_policy(Loader::ModifyPolicy, PolicyTemplates::RemoveMemberFromGroup.new(), input, resource(branch), true)

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    head(204)
    audit_success(result[:policy])
  rescue => e
    audit_failure(e, action)
    raise e
  end

  private

  def validate_remove_member_input(action, branch, group_name, member_id, member_kind, policy_id)
    validate_group_members_input(params, NUM_OF_REMOVE_DATA_PARAMS, group_name, member_kind)
    # Validate there is permissions for current user to run update on the branch
    authorize(action, resource(branch))
    # Validate group exists
    group_id = GroupMemberType.get_group_id(account, branch, group_name)
    resource_exists_validation(group_id)
    # validate resource exists
    resource_id = GroupMemberType.get_resource_id(account, member_kind, member_id)
    resource_exists_validation(resource_id)
    # Validate resource is a member in group
    unless is_role_member_of_group(resource_id, group_id, policy_id)
      raise Errors::Group::ResourceNotMember.new(member_id, member_kind, group_name)
    end
  end

  def validate_add_member_input(action, branch, group_name, member_id, member_kind, policy_id)
    validate_group_members_input(params, NUM_OF_ADD_DATA_PARAMS, group_name, member_kind)
    # Validate there is permissions for current user to run update on the branch
    authorize(action, resource(branch))
    # Validate group exists
    group_id = GroupMemberType.get_group_id(account, branch, group_name)
    resource_exists_validation(group_id)
    # Validate resource is not already a member
    verify_resource_is_not_member(group_id, member_kind, member_id, policy_id)
  end

  def verify_resource_is_not_member(group_id, member_kind, member_id, policy_id)
    resource_id = GroupMemberType.get_resource_id(account, member_kind, member_id)
    if is_role_member_of_group(resource_id, group_id, policy_id)
      raise Errors::Group::DuplicateMember.new(member_id, member_kind, group_id)
    end
  end

  def build_member_to_group_policy_input(group_name, member_kind, member_id)
    # The resource id should be absolute path so have to start with / but as its part of the api path it will be without the / at the beginning
    unless member_id.start_with?("/")
      member_id = "/#{member_id}"
    end

    {
      "id" => group_name,
      "kind" => member_kind,
      "member_id" => member_id
    }
  end

end
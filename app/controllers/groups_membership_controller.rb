# frozen_string_literal: true

class GroupsMembershipController < V2RestController
  include AuthorizeResource
  include BodyParser
  include GroupMembershipValidator
  include Secrets::RedisHandler

  NUM_OF_ADD_DATA_PARAMS = 7
  NUM_OF_REMOVE_DATA_PARAMS = 6

  def log_message_add(params)
    "Add member #{params[:kind]}:#{params[:id]} to group #{params[:branch]}/#{params[:group_name]}"
  end
  def add_member
    logger.debug{LogMessages::Endpoints::EndpointRequested.new(log_message_add(params))}
    action = :update

    group, member, member_id, member_kind = input_validation(action, NUM_OF_ADD_DATA_PARAMS)

    # If membership is already granted, grant_to will return nil.
    # In this case, throw error
    unless (membership = group.grant_to(member))
      raise Errors::Group::DuplicateMember.new(member_id, member_kind, group[:role_id])
    end

    clean_membership_cache

    logger.debug{LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message_add(params))}
    render(json: {
      kind: member_kind,
      id: member_id
    }, status: :created)
    audit_success(membership, :add)
  rescue => e
    audit_failure(e, :add)
    raise e
  end

  def log_message_remove(params)
    "Remove member #{params[:kind]}:#{params[:id]} from group #{params[:branch]}/#{params[:group_name]}"
  end

  def remove_member
    logger.debug{LogMessages::Endpoints::EndpointRequested.new(log_message_remove(params))}
    action = :update

    group, member, member_id, member_kind = input_validation(action, NUM_OF_REMOVE_DATA_PARAMS)

    membership = ::RoleMembership[role_id: group[:role_id], member_id: member[:role_id]]
    if membership
      membership.destroy
      clean_membership_cache
    else  #If the resource is not a member raise an error
      raise Errors::Group::ResourceNotMember.new(member_id, member_kind, group[:role_id])
    end

    logger.debug{LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message_remove(params))}
    head(204)
    audit_success(membership, :remove)
  rescue => e
    audit_failure(e, :remove)
    raise e
  end

  private

  def audit_success(membership, operation)
    Audit.logger.log(
      Audit::Event::Policy.new(
        operation: operation,
        subject: Audit::Subject::RoleMembership.new(membership.pk_hash),
        user: current_user,
        client_ip: request.ip
      )
    )
  end

  def audit_failure(err, operation)
    Audit.logger.log(
      Audit::Event::Policy.new(
        operation: operation,
        subject: {}, # Subject is empty because no role/resource has been impacted
        user: current_user,
        client_ip: request.ip,
        error_message: err.message
      )
    )
  end

  def input_validation(action, num_of_params)
    permitted_params = params.permit(:branch, :group_name, :kind, :id).to_h.symbolize_keys
    branch = get_branch(permitted_params)
    group_name = permitted_params[:group_name]
    member_kind = permitted_params[:kind]
    member_id = permitted_params[:id]

    # validate all input is correct
    validate_group_members_input(params, num_of_params, group_name, member_kind)

    # Validate there is permissions for current user to run update on the branch
    authorize(action, get_resource("policy", branch))

    group_id = full_resource_id("group", "#{branch}/#{group_name}")
    group = Role[group_id]
    raise Exceptions::RecordNotFound, group_id unless group

    member_full_id = get_member_full_id(member_kind, member_id)
    member = Role[member_full_id]
    raise Exceptions::RecordNotFound, member_full_id unless member

    [group, member, member_id, member_kind]
  end

  private
  def get_member_full_id(member_kind, member_id)
    #We support the member path to start with / and without but for full id we need it without /
    if member_id.start_with?("/")
      member_id = member_id[1..-1]
    end
    full_resource_id(member_kind, member_id)
  end

  def get_branch(params)
    branch = params[:branch]
    if branch.nil?
      branch = "root"
    end
    branch
  end
end
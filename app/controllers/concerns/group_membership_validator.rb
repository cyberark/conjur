# frozen_string_literal: true

module GroupMembershipValidator
  extend ActiveSupport::Concern

  def validate_conjur_admin_group(account)
    validate_account(account)

    unless is_group_ancestor_of_role(current_user.id, "#{account}:group:Conjur_Cloud_Admins")
      logger.error(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "Current user role is: #{current_user.id}. should be member of: \"group:Conjur_Cloud_Admins\""
        )
      )
      raise ApplicationController::Forbidden
    end
  end

  def validate_group_members_input(params, num_parameters, group_name, member_kind)
    # Validate body is valid
    validate_input(params, num_parameters)
    # Validate member kind is supported
    verify_kind(member_kind)
    # Validate group is not identity users groups
    verify_group_allowed(group_name)
  end

  def is_group_ancestor_of_role(role_id, group_name)
    group = Role[group_name]
    unless group&.ancestor_of?(role = Role[role_id])
      return false
    end
    return true
  end

  def is_role_member_of_group(role_id, group_id, policy_id)
    role_membership = ::RoleMembership[role_id: group_id, member_id: role_id,
                              policy_id: GroupMemberType.get_resource_id(account, "policy", policy_id)]
    !role_membership.nil?
  end

  private

  def validate_input(data, num_parameters)
    data_fields = {
      kind: String,
      id: String,
      branch: String,
      group_name: String
    }

    Util::validate_data(data, data_fields, num_parameters)
  end

  def verify_group_allowed(group_name)
    allowed_id = %w[Conjur_Cloud_Admins Conjur_Cloud_Users]
    if allowed_id.include?(group_name)
      raise Errors::Conjur::ParameterValueInvalid , "Group Name"
    end
  end

  def resource_exists_validation(resource_id)
    resource = Resource.find(resource_id: resource_id)
    if resource.nil?
      raise Exceptions::RecordNotFound.new(resource_id)
    end
  end

  def verify_kind(kind)
    allowed_kind = %w[host user group]
    unless allowed_kind.include?(kind)
      raise Errors::Conjur::ParameterValueInvalid , "Member Kind"
    end
  end

end

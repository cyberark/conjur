require_relative '../util/param_validator'

class GroupMemberType
  NUM_OF_URL_PARAMS = 3
  NUM_OF_EXPECTED_DATA_PARAMS = 4

  def self.get_branch(params)
    branch = params[:branch]
    if branch.nil?
      branch = "root"
    end
    branch
  end

  def self.validate_input(data)
    data_fields = {
      kind: String,
      id: String,
      branch: String,
      group_name: String
    }

  Util::validate_data(data, data_fields, GroupMemberType::NUM_OF_URL_PARAMS + GroupMemberType::NUM_OF_EXPECTED_DATA_PARAMS)
end

  def self.verify_group_allowed(group_name)
    allowed_id = %w[Conjur_Cloud_Admins Conjur_Cloud_Users]
    if allowed_id.include?(group_name)
      raise Errors::Conjur::ParameterValueInvalid , "Group Name"
    end
  end

  def self.group_exists_validation(group_id)
    group_resource = Resource.find(resource_id: group_id)
    if group_resource.nil?
      raise Exceptions::RecordNotFound.new(group_id)
    end
  end

  def self.verify_resource_is_not_member(group_id, member_kind, member_id)
    relative_member_id = member_id[1..-1]
    resource_id = "#{StaticAccount.account}:#{member_kind}:#{relative_member_id}"
    unless RoleMembership.where(role_id: group_id,member_id:resource_id).all.empty?
      raise Errors::Group::DuplicateMember.new(member_id, member_kind, group_id)
    end
  end

  def self.verify_kind(kind)
    allowed_kind = %w[host user group]
    unless allowed_kind.include?(kind)
      raise Errors::Conjur::ParameterValueInvalid , "Member Kind"
    end
  end

  def self.get_group_id(account, branch, group_name)
    "#{account}:group:#{branch}/#{group_name}"
  end

end

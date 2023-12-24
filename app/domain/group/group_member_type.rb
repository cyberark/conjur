require_relative '../util/param_validator'

class GroupMemberType
  NUM_OF_URL_PARAMS = 4
  NUM_OF_EXPECTED_DATA_PARAMS = 2

  def validate(params, account)
    group_id = "#{account}:group:#{params[:identifier]}"
    # Validate body is valid
    validate_input(params)
    # Validate member kind is supported
    verify_kind(params[:kind])
    # Validate group is not identity users groups
    verify_group_allowed(params)
    # Validate group exists
    group_exists_validation(group_id)
    # Validate resource is not already a member
    resource_is_member(group_id, params[:kind], params[:id], params[:identifier])
  end

  def get_group_name(identifier)
    last_delimiter_index = identifier.rindex('/')
    # If the group is under root the full identifier is the group name
    if last_delimiter_index.nil?
      group_name = identifier
    else
      group_name = identifier[(last_delimiter_index + 1)..-1]
    end
    group_name
  end

  def get_branch(identifier)
    last_delimiter_index = identifier.rindex('/')
    if last_delimiter_index.nil?
      branch = "root"
    else
      branch = identifier[0..(last_delimiter_index-1)]
    end
    branch
  end
end

private
def validate_input(data)
  data_fields = {
    kind: String,
    id: String
  }

  Util::validate_data(data, data_fields, GroupMemberType::NUM_OF_URL_PARAMS + GroupMemberType::NUM_OF_EXPECTED_DATA_PARAMS)
end

def verify_group_allowed(params)
  group_name = get_group_name(params[:identifier])
  allowed_id = %w[Conjur_Cloud_Admins Conjur_Cloud_Users]
  if allowed_id.include?(group_name)
    raise Errors::Conjur::ParameterValueInvalid , "Group Name"
  end
end

def group_exists_validation(group_id)
  group_resource = Resource.find(resource_id: group_id)
  if group_resource.nil?
    raise Exceptions::RecordNotFound.new(group_id)
  end
end

def resource_is_member(group_id, member_kind, member_id, identifier)
  relative_member_id = member_id[1..-1]
  resource_id = "rspec:#{member_kind}:#{relative_member_id}"
  unless RoleMembership.where(role_id: group_id,member_id:resource_id).all.empty?
    raise Errors::Group::DuplicateMember.new(member_id, member_kind, identifier)
  end
end

def verify_kind(kind)
  allowed_kind = %w[host user group]
  unless allowed_kind.include?(kind)
    raise Errors::Conjur::ParameterValueInvalid , "Member Kind"
  end
end

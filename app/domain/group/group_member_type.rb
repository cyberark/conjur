require_relative '../util/param_validator'

class GroupMemberType
  def self.get_branch(params)
    branch = params[:branch]
    if branch.nil?
      branch = "root"
    end
    branch
  end

  def self.validate(params, num_parameters, account, branch, group_name, member_kind)
    group_id = get_group_id(account, branch, group_name)
    # Validate body is valid
    validate_input(params, num_parameters)
    # Validate member kind is supported
    verify_kind(member_kind)
    # Validate group is not identity users groups
    verify_group_allowed(group_name)
    # Validate group exists
    group_exists_validation(group_id)
  end

  def self.get_group_id(account, branch, group_name)
    "#{account}:group:#{branch}/#{group_name}"
  end

  private

  def self.validate_input(data, num_parameters)
    data_fields = {
      kind: String,
      id: String,
      branch: String,
      group_name: String
    }

    Util::validate_data(data, data_fields, num_parameters)
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

  def self.verify_kind(kind)
    allowed_kind = %w[host user group]
    unless allowed_kind.include?(kind)
      raise Errors::Conjur::ParameterValueInvalid , "Member Kind"
    end
  end

end

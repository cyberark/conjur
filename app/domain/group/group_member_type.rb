require_relative '../util/param_validator'

class GroupMemberType
  def self.get_branch(params)
    branch = params[:branch]
    if branch.nil?
      branch = "root"
    end
    branch
  end

  def self.get_group_id(account, branch, group_name)
    "#{account}:group:#{branch}/#{group_name}"
  end

  def self.get_resource_id(account, member_kind, member_id)
    "#{account}:#{member_kind}:#{member_id}"
  end
end

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
    #We support the member path to start with / and without but for full id we need it without /
    if member_id.start_with?("/")
      member_id = member_id[1..-1]
    end
    "#{account}:#{member_kind}:#{member_id}"
  end
end

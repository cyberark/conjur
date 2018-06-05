# AssumedRole adds support allowing the requestor to assume another
# role. A query parameter (:role by default) is used to specify the
# role. If the query parameter is not present, assumed_role will be
# current_user.

# The authenticated user must hold the role being assumed, or
# ApplicationController::Forbidden will be raised.

module AssumedRole
  extend ActiveSupport::Concern

  def assumed_role?
    begin
      assumed_role
    rescue Forbidden
      nil
    end
  end

  def assumed_role(param_name = :role)
    @assumed_role ||= find_assumed_role(param_name)
  end

  private

  def find_assumed_role(param_name)
    acting_as = params[param_name].presence
    return current_user unless acting_as

    role = Role[acting_as]
    raise ApplicationController::Forbidden unless role && role.ancestor_of?(current_user)

    role
  end
end

    

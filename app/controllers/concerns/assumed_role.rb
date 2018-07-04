# frozen_string_literal: true

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

  def assumed_role(role_id = params[:role].presence)
    @assumed_role ||= find_assumed_role(role_id)
  end

  private

  def find_assumed_role(role_id)
    return current_user unless role_id

    role = Role[role_id]
    raise ApplicationController::Forbidden unless role && role.ancestor_of?(current_user)

    role
  end
end

    

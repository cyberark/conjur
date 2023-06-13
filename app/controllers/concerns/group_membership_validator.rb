# frozen_string_literal: true

module GroupMembershipValidator
  extend ActiveSupport::Concern

  def validate_conjur_admin_group(account)
    validate_account(account)

    unless is_role_member_of_group(account, current_user.id, ':group:Conjur_Cloud_Admins')
      logger.error(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "Current user role is: #{current_user.id}. should be member of: \"group:Conjur_Cloud_Admins\""
        )
      )
      raise ApplicationController::Forbidden
    end
  end

  private

  def is_role_member_of_group(account, role_id, group_name)
    role = Role[account + group_name]
    unless role&.ancestor_of?(role = Role[role_id])
      return false
    end
    return true
  end

end

# frozen_string_literal: true
#
module FindEdgePolicyResource
  include FindResource
  extend ActiveSupport::Concern

  def resource_id
    [ params[:account], "policy", "edge" ].join(":")
  end

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  def account
    @account ||= params[:account]
  end

  def resource_visible?
    return is_role_member_of_group(account, current_user.id, ':group:Conjur_Cloud_Admins')
  end
end

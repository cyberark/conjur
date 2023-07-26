# frozen_string_literal: true

module FindEdgePolicyResource
  extend ActiveSupport::Concern

  def resource_id
    [ params[:account], "policy", "edge" ].join(":")
  end


  protected

  def resource
    raise Exceptions::RecordNotFound, resource_id unless resource_visible?

    resource!
  end

  def resource_exists?
    Resource[resource_id] ? true : false
  end

  def resource_visible?
    return is_role_member_of_group(account, current_user.id, ':group:Conjur_Cloud_Admins')
  end

  private

  def resource!
    @resource ||= Resource[resource_id]
  end
end

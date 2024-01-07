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
    is_group_ancestor_of_role(current_user.id, "#{account}:group:Conjur_Cloud_Admins")
  end

  private

  def resource!
    @resource ||= Resource[resource_id]
  end
end

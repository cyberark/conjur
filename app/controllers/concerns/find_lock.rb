# frozen_string_literal: true

module FindLock
  extend ActiveSupport::Concern

  def resource_id
    id = params[:id] ? params[:id] : params[:identifier]
    [ params[:account], "webservice", "conjur/locks/#{id}" ].join(":")
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
    @resource_visible ||= resource! && @resource.visible_to?(current_user)
  end

  private

  def resource!
    @resource ||= Resource[resource_id]
  end
end

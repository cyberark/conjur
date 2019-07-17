# frozen_string_literal: true

module FindResource
  extend ActiveSupport::Concern

  def resource_id
    [ params[:account], resource_kind, params[:identifier] ].join(":")
  end

  def resource_kind
    params[:kind]
  end

  protected

  def resource
    if resource_visible?
      resource!
    else
      raise Exceptions::RecordNotFound, resource_id
    end
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

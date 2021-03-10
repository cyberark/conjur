# frozen_string_literal: true

module FindResource
  extend ActiveSupport::Concern

  def resource_id
    [ params[:account], params[:kind], params[:identifier] ].join(":")
  end

  protected

  def resource!
    @resource ||= Resource[resource_id]
  end

  def resource_visible?
    @resource_visible ||= resource! && @resource.visible_to?(current_user)
  end

  def resource
    if resource_visible?
      resource!
    else
      raise Exceptions::RecordNotFound, resource_id unless resource_visible?
    end
  end  
end

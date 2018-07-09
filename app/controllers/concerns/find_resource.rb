# frozen_string_literal: true

module FindResource
  extend ActiveSupport::Concern
  
  protected
  
  def resource_id
    [ params[:account], params[:kind], params[:identifier] ].join(":")
  end

  def resource
    @resource ||= Resource.find_if_visible(
      current_user, resource_id: resource_id
    ) or raise Exceptions::RecordNotFound, resource_id
  end  
end

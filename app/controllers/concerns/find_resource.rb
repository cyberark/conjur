module FindResource
  extend ActiveSupport::Concern
  
  protected
  
  def resource_id
    [ params[:account], params[:kind], params[:identifier] ].join(":")
  end

  def find_resource
    @resource ||= Resource.find_if_visible current_user, resource_id: resource_id
    raise Exceptions::RecordNotFound, resource_id unless @resource
  end  
end

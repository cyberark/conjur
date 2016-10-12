module FindResource
  extend ActiveSupport::Concern
  
  protected
  
  def resource_id
    [ params[:account], params[:kind], params[:identifier] ].join(":")
  end

  def find_resource
    @resource ||= Resource[resource_id]
    raise Exceptions::RecordNotFound, resource_id unless @resource
  end  
end
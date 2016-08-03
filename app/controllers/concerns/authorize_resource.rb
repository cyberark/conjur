module AuthorizeResource
  extend ActiveSupport::Concern
  
  included do
    include CurrentRole
  end
  
  def authorize(privilege)
    unless current_role.allowed_to?(privilege, @resource)
      logger.info "Current role '#{current_role.role_id}' is not permitted to '#{privilege}' resource '#{@resource.resource_id}'"
      raise Forbidden 
    end
  end      

end
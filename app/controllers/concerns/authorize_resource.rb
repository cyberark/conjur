module AuthorizeResource
  extend ActiveSupport::Concern
  
  included do
    include CurrentUser
  end
  
  def authorize privilege 
    unless current_user.allowed_to?(privilege, @resource)
      logger.info "Current user '#{current_user.role_id}' is not permitted to '#{privilege}' resource '#{@resource.resource_id}'"
      raise ApplicationController::Forbidden
    end
  end      
end

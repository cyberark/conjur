# frozen_string_literal: true

module AuthorizeResource
  extend ActiveSupport::Concern
  
  included do
    include CurrentUser
  end
  
  def authorize privilege, resource = self.resource
    auth(current_user, privilege, resource)
  end

  def authorize_many(resources, privilege)
    resources.each do |resource|
      auth(current_user, privilege, resource)
    end
  end

  private

  def cache(user, privilege, resource)
    Rails.cache.write(
      JSON.dump(
        {
          :user => user.role_id,
          :privilege => privilege,
          :resource => resource.resource_id
        }
      ), true, expires_in: 300
    )
  end

  def cached?(user, privilege, resource)
    Rails.cache.fetch(
      JSON.dump(
        {
          :user => user.role_id,
          :privilege => privilege,
          :resource => resource.resource_id
        }
      )
    )
  end

  def auth(user, privilege, resource)
    return if cached?(user, privilege, resource) 
    if user.allowed_to?(privilege, resource)
      cache(user, privilege, resource)
      return
    end
    
    logger.info(
      Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
        user.role_id,
        privilege,
        resource.resource_id
      )
    )
    raise ApplicationController::Forbidden
    
  end
end

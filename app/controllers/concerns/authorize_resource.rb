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

  def auth(user, privilege, resource)
    unless user.allowed_to?(privilege, resource)
      logger.info "Current user '#{user.role_id}' is not permitted to '#{privilege}' resource '#{resource.resource_id}'"
      raise ApplicationController::Forbidden
    end
  end
end

module CurrentRole
  extend ActiveSupport::Concern
  
  included do
    include TokenUser
  end
  
  def current_user?
    begin
      current_user
    rescue Forbidden => e
      nil
    end
  end
  
  def current_user
    @current_user ||= find_current_user
  end
  
  def current_role 
    @current_role ||= if (role_name = params[:acting_as])
      role_id = Role.make_full_id(role_name, account)
      Role[role_id].tap do |role|
        unless role
          logger.info "Role '#{role_id}' not found"
          raise ApplicationController::Forbidden
        end
        unless current_user.all_roles([ role_id ]).any?
          logger.info "Authenticated user '#{current_user.role_id}' does not have role '#{role_id}'"
          raise ApplicationController::Forbidden
        end
      end
    else
      current_user
    end
  end
  
  def current_role?(*a)
    begin
      current_role(*a)
    rescue ApplicationController::Forbidden => e
      nil
    end
  end
  
  private
  
  def find_current_user
    Role[token_user.roleid] or raise ApplicationController::Forbidden
  end
end
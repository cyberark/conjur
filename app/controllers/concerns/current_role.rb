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
          raise Forbidden
        end
        unless current_user.all_role([ role_id ]) == [ role ]
          logger.info "Authenticated user '#{current_user.role_id}' does not have role '#{role_id}'"
          raise Forbidden
        end
      end
    else
      current_user
    end
  end
  
  def current_role?(*a)
    begin
      current_role(*a)
    rescue Forbidden => e
      nil
    end
  end
  
  private
  
  def find_current_user
    Role[token_user.roleid] or raise Forbidden
  end
end
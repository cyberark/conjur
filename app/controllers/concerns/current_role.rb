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
      Role[roleid_from_username(role_name)] or raise Forbidden
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
    Role[roleid_from_username(token_user.login)] or raise Forbidden
  end
end
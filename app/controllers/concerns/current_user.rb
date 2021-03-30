# frozen_string_literal: true

module CurrentUser
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
  
  private
  
  def find_current_user
    Role[token_user.roleid] || raise(ApplicationController::Forbidden)
  end
end
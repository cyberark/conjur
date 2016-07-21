class ApplicationController < ActionController::API
  include Authenticates
    
  class Unauthorized < RuntimeError
  end
  
  rescue_from IndexError, with: :record_not_found
  rescue_from Unauthorized, with: :unauthorized
  rescue_from ArgumentError, with: :unprocessable_entity

  def record_not_found  e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    head :not_found
  end

  def unprocessable_entity  e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    head :unprocessable_entity
  end

  def unauthorized e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    head :unauthorized
  end
  
  # Gets the value of the :account parameter.
  def current_account
    @account ||= params[:account]
  end
  
  def make_full_id roleid
    Role.make_full_id roleid
  end
  
  def roleid_from_username login
    Role.roleid_from_username login
  end
end

class ApplicationController < ActionController::API
  include Authenticates
    
  class Unauthorized < RuntimeError
  end
  
  class Forbidden < RuntimeError
  end
  
  rescue_from IndexError, with: :record_not_found
  rescue_from Unauthorized, with: :unauthorized
  rescue_from Forbidden, with: :forbidden
  rescue_from ArgumentError, with: :unprocessable_entity

  def record_not_found  e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    head :not_found
  end

  def unprocessable_entity  e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    head :unprocessable_entity
  end

  def forbidden e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    head :forbidden
  end

  def unauthorized e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    head :unauthorized
  end
  
  # Gets the value of the :account parameter.
  def account
    @account ||= params[:account]
  end
end

class ApplicationController < ActionController::API
  include Authenticates
    
  class Unauthorized < RuntimeError
  end
  
  class Forbidden < RuntimeError
  end
  
  rescue_from IndexError, with: :record_not_found
  rescue_from Unauthorized, with: :unauthorized
  rescue_from Forbidden, with: :forbidden
  rescue_from Sequel::ValidationFailed, with: :validation_failed
  rescue_from ArgumentError, with: :argument_error

  def record_not_found  e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    head :not_found
  end

  def validation_failed e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    render json: {
        code: error_code_of_exception_class(e.class),
        message: e.errors.full_messages.join(". "),
        innererror: e.errors.to_h
      }, status: :unprocessable_entity
  end

  def argument_error  e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    render json: {
        code: error_code_of_exception_class(e.class),
        message: e.message
      }, status: :unprocessable_entity
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

  private

  def error_code_of_exception_class cls
    cls.to_s.underscore.split('/')[-1]
  end
end

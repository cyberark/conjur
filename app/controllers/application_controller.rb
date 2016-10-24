class ApplicationController < ActionController::API
  include Authenticates
    
  class Unauthorized < RuntimeError
  end
  
  class Forbidden < RuntimeError
  end
  
  rescue_from Exceptions::RecordNotFound, with: :record_not_found
  rescue_from Unauthorized, with: :unauthorized
  rescue_from Forbidden, with: :forbidden
  rescue_from Sequel::ValidationFailed, with: :validation_failed
  rescue_from Conjur::Policy::Invalid, with: :policy_invalid
  rescue_from ArgumentError, with: :argument_error

  around_action :run_with_transaction
 
  private
 
  # Wrap the request in a transaction.
  def run_with_transaction
    Sequel::Model.db.transaction do
      yield
    end
  end

  def record_not_found e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    render json: {
      error: {
        code: "not_found",
        message: e.message,
        target: e.kind,
        details: {
          code: "not_found",
          target: "id",
          message: e.id
        }
      }
    }, status: :not_found
  end

  def validation_failed e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    message = e.errors.map do |field, messages|
      messages.map do |message|
        [ field, message ].join(' ')
      end
    end.flatten.join(',')

    details = e.errors.map do |field, messages|
      messages.map do |message|
        {
          code: error_code_of_exception_class(e.class),
          target: field,
          message: message
        }
      end
    end.flatten

    render json: {
      error: {
        code: error_code_of_exception_class(e.class),
        message: message,
        details: details
      }
    }, status: :unprocessable_entity
  end

  def policy_invalid e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    render json: {
      error: {
        code: "policy_invalid",
        message: e.message,
        innererror: {
          code: "policy_invalid",
          filename: e.filename,
          line: e.mark.line,
          column: e.mark.column
        }
      }
    }, status: :unprocessable_entity
  end

  def argument_error  e
    logger.debug "#{e}\n#{e.backtrace.join "\n"}"
    render json: {
      error: {
        code: error_code_of_exception_class(e.class),
        message: e.message
      }
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

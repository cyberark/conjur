# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Authenticates
  include PrintBacktrace
  include ::ActionView::Layouts

  class Unauthorized < RuntimeError
    attr_reader :return_message_in_response

    def initialize(message = nil, return_message_with_response = false)
      super(message)
      @return_message_in_response = return_message_with_response
    end
  end

  class GatewayTimeout < RuntimeError
  end

  class BadGateway < RuntimeError
  end

  class BadRequest < RuntimeError
  end

  class BadRequestWithBody < RuntimeError
  end

  class InternalServerError < RuntimeError
  end

  class ServiceUnavailable < RuntimeError
  end

  class Forbidden < Exceptions::Forbidden
    def message
      'Forbidden'
    end
  end

  class RecordNotFound < Exceptions::RecordNotFound
  end

  class RecordExists < Exceptions::RecordExists
  end

  class UnprocessableEntity < RuntimeError
  end

  rescue_from Exceptions::RecordNotFound, with: :render_record_not_found
  rescue_from Errors::Conjur::MissingSecretValue, with: :render_secret_not_found
  rescue_from Errors::Conjur::DuplicateVariable, with: :render_bad_request_with_message
  rescue_from Exceptions::RecordExists, with: :record_exists
  rescue_from Exceptions::Forbidden, with: :forbidden
  rescue_from Exceptions::MethodNotAllowed, with: :method_not_allowed
  rescue_from BadRequest, with: :bad_request
  rescue_from BadRequestWithBody, with: :render_bad_request_with_message
  rescue_from Unauthorized, with: :unauthorized
  rescue_from InternalServerError, with: :internal_server_error
  rescue_from ServiceUnavailable, with: :service_unavailable
  rescue_from GatewayTimeout, with: :gateway_timeout
  rescue_from BadGateway, with: :bad_gateway
  rescue_from Exceptions::NotImplemented, with: :not_implemented
  rescue_from Sequel::ValidationFailed, with: :validation_failed
  rescue_from Sequel::NoMatchingRow, with: :no_matching_row
  rescue_from Sequel::ForeignKeyConstraintViolation, with: :foreign_key_constraint_violation
  rescue_from Conjur::PolicyParser::Invalid, with: :policy_invalid
  rescue_from Exceptions::InvalidPolicyObject, with: :policy_invalid
  rescue_from ArgumentError, with: :argument_error
  rescue_from ActionController::ParameterMissing, with: :argument_error
  rescue_from Errors::Conjur::ParameterMissing, with: :render_bad_request_with_message
  rescue_from Errors::Conjur::ParameterValueInvalid, with: :render_bad_request_with_message
  rescue_from Errors::Conjur::ParameterTypeInvalid, with: :render_bad_request_with_message
  rescue_from Errors::Conjur::NumOfParametersInvalid, with: :render_bad_request_with_message
  rescue_from UnprocessableEntity, with: :unprocessable_entity
  rescue_from Errors::Conjur::BadSecretEncoding, with: :bad_secret_encoding
  rescue_from Errors::Authentication::RoleNotApplicableForKeyRotation, with: :method_not_allowed
  rescue_from Errors::Authorization::AccessToResourceIsForbiddenForRole, with: :forbidden
  rescue_from Errors::Conjur::RequestedResourceNotFound, with: :render_resource_not_found
  rescue_from Errors::Authorization::InsufficientResourcePrivileges, with: :forbidden
  rescue_from Errors::Group::DuplicateMember, with: :render_duplicate_with_message
  rescue_from Errors::Group::ResourceNotMember, with: :render_resource_not_found
  rescue_from Errors::Conjur::APIHeaderMissing, with: :render_bad_request_with_message
  rescue_from Errors::Conjur::AnnotationNotFound, with: :render_resource_not_found

  around_action :run_with_transaction

  # sets the default content type header on incoming requests that match the
  # path_match regex
  def self.set_default_content_type_for_path(path_match, content_type)
    ::Rack::DefaultContentType.content_type_by_path[path_match] = content_type
  end

  private

  # Wrap the request in a transaction.
  def run_with_transaction(&block)
    Sequel::Model.db.transaction(&block)
  end

  def render_resource_not_found e
    logger.warn(e.to_s)
    render(json: {
      error: {
        code: "not_found",
        message: e.message
      }
    }, status: :not_found)
  end

  def no_matching_row e
    logger.warn(e.to_s)
    target = e.dataset.model.table_name.to_s.underscore rescue nil
    render(json: {
      error: {
        code: "not_found",
        target: target,
        message: e.message
      }.compact
    }, status: :not_found)
  end

  def foreign_key_constraint_violation e
    logger.warn(e.to_s)

    # Check if a foreign key constraint violation is specifically a missing record, and handle it accordingly
    #
    # Here's a sample exception:
    # <Sequel::ForeignKeyConstraintViolation: PG::ForeignKeyViolation: ERROR:  insert or update on table "permissions" violates foreign key constraint "permissions_resource_id_fkey"
    # DETAIL:  Key (resource_id)=(myConjurAccount:layer:ops) is not present in table "resources".
    # >
    if e.is_a?(Sequel::ForeignKeyConstraintViolation) &&
      e.cause.is_a?(PG::ForeignKeyViolation) &&
      (e.cause.result.error_field(PG::PG_DIAG_MESSAGE_DETAIL) =~ /Key \(([^)]+)\)=\(([^)]+)\) is not present in table "([^"]+)"/  rescue false)
      violating_key = $2
      
      exc = Exceptions::RecordNotFound.new(violating_key)
      render_record_not_found(exc)
    else
      # if this isn't a case we're handling yet, let the exception proceed
      raise e
    end
  end

  def validation_failed e
    log_error(e)
    message = e.errors.map do |field, messages|
      messages.map do |message|
        [field, message].join(' ')
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

    render(json: {
      error: {
        code: error_code_of_exception_class(e.class),
        message: message,
        details: details
      }
    }, status: :unprocessable_entity)
  end

  def policy_invalid e
    logger.warn(e.to_s)
    error = { code: "policy_invalid", message: e.message }

    if e.instance_of?(Conjur::PolicyParser::Invalid)
      error[:innererror] = {
        code: "policy_invalid",
        filename: e.filename,
        line: e.mark.line,
        column: e.mark.column
      }
    end

    render(json: { error: error }, status: :unprocessable_entity)
  end

  def argument_error e
    logger.warn(e.to_s)
    render(json: {
      error: {
        code: error_code_of_exception_class(e.class),
        message: e.message
      }
    }, status: :unprocessable_entity)
  end

  def record_exists e
    logger.warn(e.to_s)
    render(json: {
      error: {
        code: "conflict",
        message: e.message,
        target: e.kind,
        details: {
          code: "conflict",
          target: "id",
          message: e.id
        }
      }
    }, status: :conflict)
  end

  def forbidden e
    logger.warn(e.to_s)
    head(:forbidden)
  end

  def method_not_allowed e
    logger.warn(e.to_s)
    render(json: {
      error: {
        code: :method_not_allowed,
        message: e.message
      }
    }, status: :method_not_allowed)
  end

  def conflict e
    log_error(e)
    render(json: {
      error: {
        code: :conflict,
        message: e.message
      }
    }, status: :conflict)
  end

  def bad_request e
    logger.warn(e.to_s)
    head(:bad_request)
  end

  def unprocessable_entity e
    logger.warn(e.to_s)
    render(json: {
      error: {
        code: :unprocessable_entity,
        message: e.message
      }
    }, status: :unprocessable_entity)
  end

  def render_bad_request_with_message e
    logger.warn(e.to_s)
    render(json: {
      error: {
        code: :bad_request,
        message: e.message
      }
    }, status: :bad_request)
  end

  def render_duplicate_with_message e
    logger.warn(e.to_s)
    render(json: {
      error: {
        code: :conflict,
        message: e.message
      }
    }, status: :conflict)
  end

  def bad_secret_encoding e
    log_error(e)
    render(json: {
      error: {
        code: :not_acceptable,
        message: e.message
      }
    }, status: :not_acceptable)
  end

  def unauthorized e
    logger.warn(e.to_s)
    if e.return_message_in_response
      render(json: {
        error: {
          code: :unauthorized,
          message: e.message
        }
      }, status: :unauthorized)
    else
      head(:unauthorized)
    end
  end

  def internal_server_error e
    log_error(e)
    head(:internal_server_error)
  end

  def service_unavailable e
    log_error(e)
    head(:service_unavailable)
  end

  def gateway_timeout e
    log_error(e)
    head(:gateway_timeout)
  end

  def bad_gateway e
    log_error(e)
    head(:bad_gateway)
  end

  def not_implemented e
    log_error(e)
    render(json: {
      error: {
        code: "not_implemented",
        message: e.message
      }
    }, status: :not_implemented)
  end

  # Gets the value of the :account parameter.
  def account
    @account ||= params[:account]
  end

  def render_secret_not_found e
    logger.debug(e.to_s)
    render(json: {
      error: {
        code: "not_found",
        message: e.message
      }
    }, status: :not_found)
  end

  def render_record_not_found e
    logger.debug(e.to_s)
    render(json: {
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
    }, status: :not_found)
  end

  def error_code_of_exception_class cls
    cls.to_s.underscore.split('/')[-1]
  end

  def log_error e
    logger.error(e.to_s)
    log_backtrace(e) unless e.backtrace.nil?
  end
end

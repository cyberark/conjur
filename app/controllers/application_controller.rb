# frozen_string_literal: true

require 'exceptions/enhanced_policy'

class ApplicationController < ActionController::API
  include Authenticates
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

  rescue_from Exceptions::RecordNotFound, with: :record_not_found
  rescue_from Errors::Conjur::MissingSecretValue, with: :render_secret_not_found
  rescue_from Exceptions::RecordExists, with: :record_exists
  rescue_from Exceptions::Forbidden, with: :forbidden
  rescue_from PG::InsufficientPrivilege, with: :not_allowed
  rescue_from BadRequest, with: :bad_request
  rescue_from Unauthorized, with: :unauthorized
  rescue_from InternalServerError, with: :internal_server_error
  rescue_from ServiceUnavailable, with: :service_unavailable
  rescue_from GatewayTimeout, with: :gateway_timeout
  rescue_from BadGateway, with: :bad_gateway
  rescue_from Exceptions::NotImplemented, with: :not_implemented
  rescue_from Sequel::ValidationFailed, with: :validation_failed
  rescue_from Sequel::NoMatchingRow, with: :no_matching_row
  rescue_from Sequel::ForeignKeyConstraintViolation, with: :foreign_key_constraint_violation
  rescue_from Exceptions::EnhancedPolicyError, with: :enhanced_policy_error
  rescue_from Exceptions::InvalidPolicyObject, with: :policy_invalid
  rescue_from Conjur::PolicyParser::Invalid, with: :policy_invalid
  rescue_from Conjur::PolicyParser::ResolverError, with: :policy_invalid
  rescue_from NoMethodError, with: :validation_failed
  rescue_from ArgumentError, with: :argument_error
  rescue_from ActionController::ParameterMissing, with: :argument_error
  rescue_from UnprocessableEntity, with: :unprocessable_entity
  rescue_from Errors::Conjur::BadSecretEncoding, with: :bad_secret_encoding
  rescue_from Errors::Authentication::RoleNotApplicableForKeyRotation, with: :method_not_allowed
  rescue_from Errors::Authorization::AccessToResourceIsForbiddenForRole, with: :forbidden
  rescue_from Errors::Conjur::RequestedResourceNotFound, with: :resource_not_found
  rescue_from Errors::Authorization::InsufficientResourcePrivileges, with: :forbidden

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

  def resource_not_found e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    render_resource_not_not_found(e)
  end

  def render_resource_not_not_found e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: "not_found",
        message: e.message
      }
    }, status: :not_found)
  end

  def record_not_found e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    render_record_not_found(e)
  end

  def no_matching_row e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
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
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")

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
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
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
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")

    msg = e.message == nil ? e.to_s : e.message
    error = { code: "policy_invalid", message: msg }

    if e.instance_of?(Conjur::PolicyParser::Invalid)
      error[:innererror] = {
        code: "policy_invalid",
        filename: e.filename,
        line: e.line,
        column: e.column
      }
    end

    render(json: { error: error }, status: :unprocessable_entity)
  end

  def enhanced_policy_error e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")

    code = e.original_error.instance_of?(Conjur::PolicyParser::ResolverError) ? "validation_failed" : "policy_invalid"

    render(json: {
      error: {
        code: code,
        message: e.message
      }
    }, status: :unprocessable_entity)
  end

  def argument_error e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")

    render(json: {
      error: {
        code: error_code_of_exception_class(e.class),
        message: e.message
      }
    }, status: :unprocessable_entity)
  end

  def record_exists e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
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
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    head(:forbidden)
  end

  def method_not_allowed e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: :method_not_allowed,
        message: e.message
      }
    }, status: :method_not_allowed)
  end

  def conflict e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: :conflict,
        message: e.message
      }
    }, status: :conflict)
  end

  def bad_request e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    head(:bad_request)
  end

  def unprocessable_entity e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: :unprocessable_entity,
        message: e.message
      }
    }, status: :unprocessable_entity)
  end

  def bad_secret_encoding e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: :not_acceptable,
        message: e.message
      }
    }, status: :not_acceptable)
  end

  def unauthorized e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
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
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    head(:internal_server_error)
  end

  def service_unavailable e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    head(:service_unavailable)
  end

  def gateway_timeout e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    head(:gateway_timeout)
  end

  def bad_gateway e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    head(:bad_gateway)
  end

  def not_implemented e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: "not_implemented",
        message: e.message
      }
    }, status: :not_implemented)
  end

  def not_allowed e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")

    error_message = if request.get?
      "Read operations are not allowed"
    else
      "Write operations are not allowed"
    end

    render(json: {
      error: {
        code: 405,
        message: error_message
      }
    }, status: 405)
  end

  # Gets the value of the :account parameter.
  def account
    @account ||= params[:account]
  end

  def render_secret_not_found e
    logger.debug("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: "not_found",
        message: e.message
      }
    }, status: :not_found)
  end

  def render_record_not_found e
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
end

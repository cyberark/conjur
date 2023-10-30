# frozen_string_literal: true

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
  rescue_from Errors::Conjur::DuplicateVariable, with: :render_duplicate_variable
  rescue_from Exceptions::RecordExists, with: :record_exists
  rescue_from Exceptions::Forbidden, with: :forbidden
  rescue_from Exceptions::MethodNotAllowed, with: :method_not_allowed
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
  rescue_from Conjur::PolicyParser::Invalid, with: :policy_invalid
  rescue_from Exceptions::InvalidPolicyObject, with: :policy_invalid
  rescue_from Exceptions::DisallowedPolicyOperation, with: :disallowed_policy_operation
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
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    render_resource_not_not_found(e)
  end

  def render_resource_not_not_found e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: "not_found",
        message: e.message
      }
    }, status: :not_found)
  end

  def record_not_found e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    render_record_not_found(e)
  end

  def no_matching_row e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
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
    logger.error("#{e}\n#{e.backtrace.join("\n")}")

    # check if this is a violation of role_memberships_member_id_fkey
    # or role_memberships_role_id_fkey
    # sample exceptions:
    # PG::ForeignKeyViolation: ERROR:  insert or update on table "role_memberships" violates foreign key constraint "role_memberships_member_id_fkey"
    # DETAIL:  Key (member_id)=(cucumber:group:security-admin) is not present in table "roles".
    # or
    # PG::ForeignKeyViolation: ERROR:  insert or update on table "role_memberships" violates foreign key constraint "role_memberships_role_id_fkey"
    # DETAIL:  Key (role_id)=(cucumber:group:developers) is not present in table "roles".
    if e.message.index(/role_memberships_member_id_fkey/) ||
      e.message.index(/role_memberships_role_id_fkey/)

      key_string = ''
      e.message.split(" ").map do |text|
        if text["(member_id)"] || text["(role_id)"]
          key_string = text
          break
        end
      end

      # the member ID is inside the second set of parentheses of the key_string
      key_index = key_string.index(/\(/, 1) + 1
      key = key_string[key_index, key_string.length - key_index - 1]

      exc = Exceptions::RecordNotFound.new(key, message: "Role #{key} does not exist")
      render_record_not_found(exc)
    else
      # if this isn't a case we're handling yet, let the exception proceed
      raise e
    end
  end

  def validation_failed e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
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
    logger.error("#{e}\n#{e.backtrace.join("\n")}")

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

  def disallowed_policy_operation e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")

    render(json: {
      error: {
        code: "disallowed_policy_operation",
        message: e.message
      }
    }, status: :unprocessable_entity)
  end

  def argument_error e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")

    render(json: {
      error: {
        code: error_code_of_exception_class(e.class),
        message: e.message
      }
    }, status: :unprocessable_entity)
  end

  def record_exists e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
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
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    head(:forbidden)
  end

  def method_not_allowed e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: :method_not_allowed,
        message: e.message
      }
    }, status: :method_not_allowed)
  end

  def conflict e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: :conflict,
        message: e.message
      }
    }, status: :conflict)
  end

  def bad_request e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    head(:bad_request)
  end

  def unprocessable_entity e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: :unprocessable_entity,
        message: e.message
      }
    }, status: :unprocessable_entity)
  end

  def render_duplicate_variable e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: :bad_request,
        message: e.message
      }
    }, status: :bad_request)
  end

  def bad_secret_encoding e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: :not_acceptable,
        message: e.message
      }
    }, status: :not_acceptable)
  end

  def unauthorized e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
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
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    head(:internal_server_error)
  end

  def service_unavailable e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    head(:service_unavailable)
  end

  def gateway_timeout e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    head(:gateway_timeout)
  end

  def bad_gateway e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    head(:bad_gateway)
  end

  def not_implemented e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
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
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
    render(json: {
      error: {
        code: "not_found",
        message: e.message
      }
    }, status: :not_found)
  end

  def render_record_not_found e
    logger.error("#{e}\n#{e.backtrace.join("\n")}")
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

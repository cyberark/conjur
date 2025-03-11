# frozen_string_literal: true

require './app/controllers/concerns/validators/api_validator'
class V2RestController < RestController
  include APIValidator

  API_V2_HEADER='application/x.secretsmgr.v2beta+json'

  before_action :validate_header
  after_action :update_response_header

  def path_identifier
    params[:identifier]
  end

  class Paging
    attr_reader :offset, :limit

    def initialize(input)
      @offset = input.fetch(:offset, -1).to_i
      @limit  = input.fetch(:limit, -1).to_i
    end

    def limit?
      @limit > -1
    end

    def offset?
      @offset > -1
    end
  end

  def update_response_header
    response.headers['Content-Type'] = request.headers['Accept'] || API_V2_HEADER
  end

  def body_str
    JSON.generate(body_payload)
  end

  def audit_success(resource_type, operation, resource_identifier, body_json_str = nil)
    audit_event(operation, resource_type, resource_identifier, body_json_str, nil)
  end

  def audit_failure(resource_type, operation, resource_identifier, failure_message, body_json_str = nil)
    audit_event(operation, resource_type, resource_identifier, body_json_str, failure_message)
  end

  private

  def audit_event(operation, resource_type, resource_identifier, body_json_str, failure_message)
    Audit.logger.log(
      Audit::Event::V2Resource.new(
        operation: operation,
        resource_type: resource_type,
        resource_name: resource_identifier,
        request_path: request.path,
        request_body: body_json_str,
        user: current_user.role_id,
        client_ip: request.ip,
        error_message: failure_message
      )
    )
  end
end

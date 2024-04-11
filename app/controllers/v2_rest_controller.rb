require './app/domain/resources/resources_handler'
class V2RestController < RestController
  include APIValidator
  include ResourcesHandler

  before_action :validate_header
  before_action :current_user
  after_action  :update_response_header

  def update_response_header
    if response.headers['Content-Type'].nil?
      response.headers['Content-Type'] = 'application/x.secretsmgr.v2+json'
    else
      response.headers['Content-Type'] = response.headers['Content-Type'].sub('application/json', 'application/x.secretsmgr.v2+json')
    end
  end

  def send_success_audit(resource_type, operation, branch, resource_name, path, body)
    send_audit(resource_type,operation, branch, resource_name, path, body, nil)
  end
  def send_failure_audit(resource_type, operation, branch, resource_name, path, body, failure_message)
    send_audit(resource_type,operation, branch, resource_name, path, body, failure_message)
  end

  private
  def send_audit(resource_type,operation, branch, resource_name, path, body , failure_message)
    full_resource_name = "#{branch}/#{resource_name}"
    json_body_string = nil
    #for secret: replace secret value with xxxxx for security
    if body
      # Parse JSON string into a Ruby hash
      if body.has_key?("value")
        # Update the value of the field if it exists
        body["value"] = "xxxxxxx"
      end
      # Convert Ruby hash back to JSON string
      json_body_string = JSON.generate(body)
    end
    Audit.logger.log(
      Audit::Event::V2Resource.new(
        operation: operation,
        resource_type: resource_type,
        resource_name: full_resource_name,
        request_path: path,
        request_body: json_body_string,
        user: current_user.role_id,
        client_ip: request.ip,
        error_message: failure_message
      )
    )
  end
end
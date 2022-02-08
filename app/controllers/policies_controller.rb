# frozen_string_literal: true
class PoliciesController < RestController
  include FindResource
  include AuthorizeResource

  before_action :current_user
  before_action :find_or_create_root_policy

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  # Conjur policies are YAML documents, so we assume that if no content-type
  # is provided in the request.
  set_default_content_type_for_path(%r{^/policies}, 'application/x-yaml')

  def put
    authorize(:update)
    load_policy(:replace)
  end

  def patch
    authorize(:update)
    load_policy(:modify)
  end

  def post
    authorize(:create)
    load_policy(:create)
  end

  protected

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  private

  def load_policy(action)
    apply_policy_response = Conjur::ApplyPolicy.new(
      current_user: current_user,
      logger: logger
    ).call(
      policy: resource,
      request_obj: request,
      modification: action
    )

    render(json: apply_policy_response, status: :created)
  rescue => e
    audit_failure(e, action)
    raise e
  end

  def audit_failure(err, operation)
    Audit.logger.log(
      Audit::Event::Policy.new(
        operation: operation,
        subject: {}, # Subject is empty because no role/resource has been impacted
        user: current_user,
        client_ip: request.ip,
        error_message: err.message
      )
    )
  end

  def concurrent_load(_exception)
    response.headers['Retry-After'] = retry_delay
    render(json: {
      error: {
        code: "policy_conflict",
        message: "Concurrent policy load in progress, please retry"
      }
    }, status: :conflict)
  end

  # Delay in seconds to advise the client to wait before retrying on conflict.
  # It's randomized to avoid request bunching.
  def retry_delay
    rand(1..8)
  end
end

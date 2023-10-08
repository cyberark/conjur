# frozen_string_literal: true

class PoliciesController < RestController
  include FindResource
  include AuthorizeResource
  include Authentication::OptionalApiKey
  
  before_action :current_user
  before_action :find_or_create_root_policy

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  # Conjur policies are YAML documents, so we assume that if no content-type
  # is provided in the request.
  set_default_content_type_for_path(%r{^/policies}, 'application/x-yaml')

  def put
    load_policy(:update, Loader::ReplacePolicy, true)
  end

  def patch
    load_policy(:update, Loader::ModifyPolicy, true)
  end

  def post
    load_policy(:create, Loader::CreatePolicy, false)
  end

  protected

  # Returns newly created roles
  def perform(policy_action)
    policy_action.track_role_changes(:annotations, ->(a) { annotation_relevant?(a) })
    policy_action.call
    new_actor_roles = actor_roles(policy_action.new_roles, %w[user host])
    created_roles = create_roles(new_actor_roles)
    updated_actor_roles = actor_roles(policy_action.updated_roles, %w[host])
    updated_roles = update_roles(updated_actor_roles)
    created_roles.merge(updated_roles)
  end

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  private

  def load_policy(action, loader_class, delete_permitted)
    authorize(action)
    policy = save_submitted_policy(delete_permitted: delete_permitted)
    loaded_policy = loader_class.from_policy(policy)
    created_roles = perform(loaded_policy)
    audit_success(policy)

    render(json: {
      created_roles: created_roles,
      version: policy[:version]
    }, status: :created)
  rescue => e
    audit_failure(e, action)
    raise e
  end

  def audit_success(policy)
    policy.policy_log.lazy.map(&:to_audit_event).each do |event|
      Audit.logger.log(event)
      log_ephemeral_variable(event)
    end
  end

  def log_ephemeral_variable(audit_event)
    if not audit_event.subject.is_a?(Audit::Subject::Resource)
      return
    end
    if audit_event.subject.to_h[:resource].include?("variable:data/ephemerals")
      logger.info(LogMessages::Ephemeral::EphemeralVariableTelemetry.new(audit_event.operation, audit_event.subject.to_h[:resource], request.ip))
    end
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

  def save_submitted_policy(delete_permitted:)
    policy_version = PolicyVersion.new(
      role: current_user,
      policy: resource,
      policy_text: request.raw_post,
      client_ip: request.ip
    )
    policy_version.delete_permitted = delete_permitted
    policy_version.save
  end

  def actor_roles(roles, kinds)
    roles.select do |role|
      kinds.member?(role.kind)
    end
  end

  def create_roles(actor_roles)
    actor_roles.each_with_object({}) do |role, memo|
      credentials = Credentials[role: role] || Credentials.create(role: role)
      role_id = role.id
      memo[role_id] = { id: role_id, api_key: credentials.api_key }
    end
  end

  def update_roles(actor_roles)
    actor_roles.each_with_object({}) do |role, memo|
      api_key = update_role_credentials(role)
      role_id = role.id
      memo[role_id] = { id: role_id, api_key: api_key }
    end
  end
end

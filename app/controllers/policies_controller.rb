# frozen_string_literal: true

class PoliciesController < RestController
  include FindResource
  include AuthorizeResource
  before_action :current_user
  before_action :find_or_create_root_policy
  after_action :publish_event, if: -> { response.successful? }
  
  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  # Conjur policies are YAML documents, so we assume that if no content-type
  # is provided in the request.
  set_default_content_type_for_path(%r{^/policies}, 'application/x-yaml')

  def put
    if params[:validate] == 'true'
      validate_policy(:validate, Loader::ValidateReplacePolicy, true)
    else
      load_policy(:update, Loader::ReplacePolicy, true)
    end
  end

  def patch
    if params[:validate] == 'true'
      validate_policy(:validate, Loader::ValidatePolicy, true)
    else
      load_policy(:update, Loader::ModifyPolicy, true)
    end
  end
 
  def post
    if params[:validate] == 'true'
      validate_policy(:validate, Loader::ValidatePolicy, false)
    else
      load_policy(:create, Loader::CreatePolicy, false)
    end
  end

  protected

  # Returns newly created roles
  def perform(policy_action)
    policy_action.call
    new_actor_roles = actor_roles(policy_action.new_roles)
    create_roles(new_actor_roles)
  end

  def validate(policy_action)
    policy_action.call
    policy_action.results
  end

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  private

  def load_policy(action, loader_class, delete_permitted)
    authorize(action)
    loader_class.authorize(current_user, self.resource)

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

  def validate_policy(action, loader_class, delete_permitted)
    authorize(action)
    loader_class.authorize(current_user, self.resource)

    # TODO: The below validation operations will on PolicyVersion, which
    # validates the syntax of the policy text. Currently it is not suited to
    # the task, since it relies on database operations. Follow up work is needed
    # to implement validation appropriately.
    #
    # policy = save_submitted_policy(delete_permitted: delete_permitted)
    # loaded_policy = loader_class.from_policy(policy)
    # result = validate(loaded_policy)
    result = true

    # Audit a successful validation.
    #
    # NOTE: this is created directly because we do not currently have a
    # PolicyVersion object that we can convert invoke `to_audit_event` on. When
    # we have this object, the audit log should be able to indicate at the
    # very least, which policy branch was validated.
    Audit.logger.log(
      Audit::Event::Policy.new(
        operation: action,
        subject: {}, # Subject is empty because no role/resource has been impacted
        user: current_user,
        client_ip: request.ip,
        error_message: nil # No error message because validation was successful
      )
    )

    render(json: {
      ok: result
    }, status: :ok)
  rescue => e
    audit_failure(e, action)
    raise e
  end

  def audit_success(policy)
    policy.policy_log.lazy.map(&:to_audit_event).each do |event|
      Audit.logger.log(event)
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

  def actor_roles(roles)
    roles.select do |role|
      %w[user host].member?(role.kind)
    end
  end

  def create_roles(actor_roles)
    actor_roles.each_with_object({}) do |role, memo|
      credentials = Credentials[role: role] || Credentials.create(role: role)
      role_id = role.id
      memo[role_id] = { id: role_id, api_key: credentials.api_key }
    end
  end

  def publish_event
    Monitoring::PubSub.instance.publish('conjur.policy_loaded')
  end
end

# frozen_string_literal: true

class PoliciesController < RestController
  include FindResource
  include AuthorizeResource
  
  before_action :current_user
  before_action :find_or_create_root_policy

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  # Conjur policies are YAML documents, so we assume that if no content-type
  # is provided in the request.
  set_default_content_type_for_path(%r{^\/policies}, 'application/x-yaml')

  def put
    authorize :update

    policy = save_submitted_policy(delete_permitted: true)
    replace_policy = Loader::ReplacePolicy.from_policy(policy)
    created_roles = perform(replace_policy)

    render json: {
      created_roles: created_roles,
      version: policy.version
    }, status: :created
  end

  def patch
    authorize :update

    policy = save_submitted_policy(delete_permitted: true)
    modify_policy = Loader::ModifyPolicy.from_policy(policy)
    created_roles = perform(modify_policy)

    render json: {
      created_roles: created_roles,
      version: policy.version
    }, status: :created
  end

  def post
    authorize :create

    policy = save_submitted_policy(delete_permitted: false)
    create_policy = Loader::CreatePolicy.from_policy(policy)
    created_roles = perform(create_policy)

    render json: {
      created_roles: created_roles,
      version: policy.version
    }, status: :created
  end

  protected

  # Returns newly created roles
  def perform(policy_action)
    policy_action.call
    new_actor_roles = actor_roles(policy_action.new_roles)
    create_roles(new_actor_roles)
  end

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  private

  def concurrent_load(_exception)
    response.headers['Retry-After'] = retry_delay
    render json: {
      error: {
        code: "policy_conflict",
        message: "Concurrent policy load in progress, please retry"
      }
    }, status: :conflict
  end

  # Delay in seconds to advise the client to wait before retrying on conflict.
  # It's randomized to avoid request bunching.
  def retry_delay
    rand 1..8
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
      %w(user host).member?(role.kind)
    end
  end

  def create_roles(actor_roles)
    actor_roles.each_with_object({}) do |role, memo|
      credentials = Credentials[role: role] || Credentials.create(role: role)
      role_id = role.id
      memo[role_id] = { id: role_id, api_key: credentials.api_key }
    end
  end
end

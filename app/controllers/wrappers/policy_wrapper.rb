# frozen_string_literal: true

# Policy wrapper to include stuff already existing in policies_controller.rb,
# to allow flexibility for rest endpoint who will use it differently

require_relative 'templates_renderer'

module PolicyWrapper
  extend ActiveSupport::Concern
  include PolicyTemplates::TemplatesRenderer
  include Authentication::OptionalApiKey

  def load_policy(loader_class, delete_permitted, resource)
    begin
      policy = save_submitted_policy(delete_permitted: delete_permitted, resource: resource)
      loaded_policy = loader_class.from_policy(policy)
      created_roles = perform(loaded_policy)
      { created_roles: created_roles, policy: policy }
    rescue Sequel::UniqueConstraintViolation => e
      concurrent_load
    end
  end

  def submit_policy(policy_loader, policy_tamplate, input, resource)
    result_yaml = renderer(policy_tamplate, input)
    set_raw_policy(result_yaml)
    result = load_policy(policy_loader, false, resource)
    result
  end

  def raw_policy
    @raw_policy
  end

  def set_raw_policy(raw_policy)
    @raw_policy = raw_policy
  end

  def save_submitted_policy(delete_permitted:, resource:)
    policy_version = PolicyVersion.new(
      role: current_user,
      policy: resource,
      policy_text: raw_policy,
      client_ip: request.ip
    )
    policy_version.delete_permitted = delete_permitted
    policy_version.save
  end

  def perform(policy_action)
    policy_action.track_role_changes_by_table(:annotations, ->(a) { annotation_relevant?(a) })
    policy_action.call
    new_actor_roles = actor_roles(policy_action.new_roles, %w[user host])
    created_roles = create_roles(new_actor_roles)
    updated_actor_roles = actor_roles(policy_action.updated_roles, %w[host])
    updated_roles = update_roles(updated_actor_roles)
    created_roles.merge(updated_roles)
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
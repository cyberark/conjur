# frozen_string_literal: true

# Policy wrapper to include stuff already existing in policies_controller.rb,
# to allow flexibility for rest endpoint who will use it differently
module PolicyWrapper
  extend ActiveSupport::Concern

  def load_policy(loader_class, delete_permitted)
    policy = save_submitted_policy(delete_permitted: delete_permitted)
    loaded_policy = loader_class.from_policy(policy)
    created_roles = perform(loaded_policy)
    { created_roles: created_roles, policy: policy }
  end

  def raw_policy
    @raw_policy
  end

  def set_raw_policy(raw_policy)
    @raw_policy = raw_policy
  end

  def save_submitted_policy(delete_permitted:)
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
    policy_action.call
    new_actor_roles = actor_roles(policy_action.new_roles)
    create_roles(new_actor_roles)
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
end
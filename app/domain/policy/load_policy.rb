# frozen_string_literal: true

module Policy
  class LoadPolicy
    include AuthorizeResource
    attr_reader :logger

    def initialize(loader_class: Loader::ModifyPolicy, audit_logger: ::Audit.logger, logger: Rails.logger)
      @loader_class = loader_class
      @audit_logger = audit_logger
      @logger = logger
    end

    def call(delete_permitted:, action:, resource:, policy_text:, current_user:, client_ip:)
      auth(current_user, action, resource)

      policy = save_submitted_policy(
        delete_permitted: delete_permitted,
        current_user: current_user,
        policy_text: policy_text,
        resource: resource,
        client_ip: client_ip
      )
      loaded_policy = @loader_class.from_policy(policy)
      created_roles = perform(loaded_policy)
      audit_success(policy)

      { created_roles: created_roles, policy: policy }
    rescue => e
      audit_failure(e, action, current_user, client_ip)
      raise e
    end

    def audit_success(policy)
      policy.policy_log.lazy.map(&:to_audit_event).each do |event|
        @audit_logger.log(event)
      end
    end

    def audit_failure(err, operation, current_user, client_ip)
      @audit_logger.log(
        Audit::Event::Policy.new(
          operation: operation,
          subject: {}, # Subject is empty because no role/resource has been impacted
          user: current_user,
          client_ip: client_ip,
          error_message: err.message
        )
      )
    end

    # Delay in seconds to advise the client to wait before retrying on conflict.
    # It's randomized to avoid request bunching.
    def retry_delay
      rand(1..8)
    end

    def save_submitted_policy(delete_permitted:, current_user:, policy_text:, resource:, client_ip:)
      policy_version = PolicyVersion.new(
        role: current_user,
        policy: resource,
        policy_text: policy_text,
        client_ip: client_ip
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
end

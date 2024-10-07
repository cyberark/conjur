module CommandHandler
  class Policy
    def initialize(
      rbac: RBAC::Permission.new,
      resource_repository: ::Resource,
      logger: Rails.logger,
      audit_logger: Audit.logger
    )
      @logger = logger
      @audit_logger = audit_logger
      @rbac = rbac
      @resource_repository = resource_repository

      # Defined here for visibility. We shouldn't need to mock these.
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def call(target_policy_id:, context:, policy:, loader:, request_type:)
      response = request_type_to_action(request_type).bind do |action|
        permitted?(target_policy_id: target_policy_id, role: context.role, privilege: action, loader: loader).bind do |target_policy|
          save_policy(context: context, policy: policy, delete_permitted: action == :update, target_policy: target_policy).bind do |policy_version|
            apply_policy(loader: loader, policy_version: policy_version).bind do |loaded_policy|
              create_roles(loaded_policy).bind do |created_roles|
                audit_success(policy_version)
                return @success.new({
                  created_roles: created_roles,
                  version: policy_version[:version]
                })
              end
            end
          end
        end
      end

      request_type_to_action(request_type).bind do |action|
        audit_failure(response.exception, action, context)
      end
      response
    end

    private

    def audit_failure(err, operation, context)
      @audit_logger.log(
        Audit::Event::Policy.new(
          operation: operation,
          subject: {}, # Subject is empty because no role/resource has been impacted
          user: context.role,
          client_ip: context.request_ip,
          error_message: err.message
        )
      )
    end

    def audit_success(policy)
      policy.policy_log.lazy.map(&:to_audit_event).each do |event|
        @audit_logger.log(event)
      end
    end

    def create_roles(loaded_policy)
      loaded_policy.call
      generate_role_credentials(loaded_policy.new_roles)
    end

    def generate_role_credentials(roles)
      rtn = {}.tap do |results|
        roles.each do |role|
          next unless %w[user host].member?(role.kind)

          credentials = Credentials[role: role] || Credentials.create(role: role)
          role_id = role.id
          results[role_id] = { id: role_id, api_key: credentials.api_key }
        end
      end
      @success.new(rtn)
    rescue => e
      @failure.new(e.message, exception: e)
    end

    def apply_policy(loader:, policy_version:)
      @success.new(
        loader.from_policy(
          policy_version.policy_parse,
          policy_version,
          Loader::Orchestrate
        )
      )
    rescue => e
      @failure.new(e.message, exception: e)
    end

    def save_policy(context:, policy:, delete_permitted:, target_policy:)
      policy_version = PolicyVersion.new(
        role: context.role,
        policy: target_policy,
        policy_text: policy,
        client_ip: context.request_ip
      )
      policy_version.delete_permitted = delete_permitted
      policy_version.save
      @success.new(policy_version)
    rescue => e
      @failure.new(e.message, exception: e)
    end

    def request_type_to_action(request_type)
      return @success.new(:update) if %w[PUT PATCH].include?(request_type)
      return @success.new(:create) if request_type == 'POST'

      @failure.new("Invalid request type: '#{request_type}' must be PUT, PATCH, or POST")
    end

    def permitted?(target_policy_id:, role:, privilege:, loader:)
      @rbac.permitted?(resource_id: target_policy_id, privilege: privilege, role: role).bind do
        target_policy = @resource_repository[target_policy_id]
        begin
          loader.authorize(role, target_policy)
        rescue => e
          @failure.new(
            "Role '#{role}' does not have permission to #{privilege} policy '#{target_policy_id}'",
            exception: e
          )
        end
        @success.new(target_policy)
      end
    end
  end
end

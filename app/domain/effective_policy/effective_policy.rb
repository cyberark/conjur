# frozen_string_literal: true

module EffectivePolicy

  class GetEffectivePolicy

    def initialize(
      logger = Rails.logger,
      config = Rails.application.config.conjur_config,
      resource_repository = Resource,
      role_id:,
      account:,
      identifier:,
      depth: nil,
      limit: nil
    )
      @logger = logger
      @config = config
      @resource_repository = resource_repository

      logger.debug("input identifier = #{identifier}")
      logger.debug("input depth      = #{depth}")
      logger.debug("input limit      = #{limit}")

      root_pol_identifier = identifier == 'root' ? '' : identifier
      @absolute_depth = absolute_depth(root_pol_identifier, depth, config.effective_policy_max_depth)
      @limit = parse_int(:limit, limit, config.effective_policy_max_limit)

      root_pol_id_pattern = "#{root_pol_identifier.empty? ? '%' : root_pol_identifier}(|/%)"
      root_pol_user_id_pattern = root_pol_identifier.empty? ? '%' : "%@#{root_pol_identifier.tr('/', '-')}(|-%)"

      params = { role_id: role_id, account: account, root_pol_identifier: root_pol_identifier,
                 root_pol_id_pattern: root_pol_id_pattern, root_pol_user_id_pattern: root_pol_user_id_pattern,
                 absolute_depth: @absolute_depth }
      logger.debug("params = #{params}")

      @res_scopes = EffectivePolicy::ResourceScopes.new(@resource_repository,
                                                        role_id: role_id, account: account,
                                                        root_pol_id_pattern: root_pol_id_pattern,
                                                        absolute_depth: @absolute_depth)

      @user_scopes = EffectivePolicy::UserScopes.new(@resource_repository,
                                                     role_id: role_id, account: account,
                                                     root_pol_user_id_pattern: root_pol_user_id_pattern,
                                                     absolute_depth: @absolute_depth)

      @user_policy_resolver = EffectivePolicy::UserPolicyResolver.new(@absolute_depth, root_pol_user_id_pattern)
    end

    def verify
      @logger.debug("Start verification for fetching effective policy")

      res_values = @res_scopes.count_and_depth_resources.first.values

      total_count = res_values[:count]
      total_count += run_count(@res_scopes.count_annotations)
      total_count += run_count(@res_scopes.count_permissions)

      @logger.debug("Computed resources depth = #{res_values[:depth]} and count = #{total_count}")

      verify_policy_depth(res_values[:depth])
      verify_policy_size(total_count)
      self
    end

    def call
      @logger.debug("Fetching effective policy")
      resources = @res_scopes.fetch_resources
        .order(:resource_id, :owner_id)
        .all
        .concat(@user_scopes.fetch_users
                                     .order(:resource_id, :owner_id)
                                     .all)

      @logger.debug("Resolving ids for users")
      @user_policy_resolver.resolve_and_filter(resources)
    end

    def to_s
      instance_variables.map { |var| "#{var}: #{instance_variable_get(var)}" }.join(", ")
    end

    private

    def run_count(scope)
      scope.first.values[:count]
    end

    def absolute_depth(root_pol_identifier, depth, max_depth)
      relative_depth = parse_int(:depth, depth, max_depth)
      root_pol_identifier.count('/') + relative_depth
    end

    def verify_policy_depth(policy_depth)
      return policy_depth if policy_depth >= 0 || policy_depth <= @absolute_depth

      raise(Errors::EffectivePolicy::PolicySizeExceeded.new(:depth, @absolute_depth, policy_depth))
    end

    def verify_policy_size(policy_count)
      return policy_count unless policy_count > @limit

      raise(Errors::EffectivePolicy::PolicySizeExceeded.new(:limit, @limit, policy_count))
    end

    def parse_int(name, value, max)
      return max if value.nil?

      val_int = Integer(value) # can rise ArgumentError
      return val_int if val_int >= 0 && val_int <= max

      raise(Errors::EffectivePolicy::NumberParamError.new(name, value, 0, max))
    rescue ArgumentError
      raise(Errors::EffectivePolicy::NumberParamError.new(name, value, 0, max))
    end
  end
end

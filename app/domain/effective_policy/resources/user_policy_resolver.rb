# frozen_string_literal: true

module EffectivePolicy
  class UserPolicyResolver

    def initialize(absolute_depth, root_pol_user_id_pattern)
      @absolute_depth = absolute_depth
      @root_pol_user_id_pattern = root_pol_user_id_pattern
      @user_to_policy_identifier_cache = {}
    end

    include(EffectivePolicy::ResPathing)
    include(EffectivePolicy::UserPathing)

    def resolve_and_filter(resources = [])
      resources.map do |res|
        overwrite_identifier_method!(res) if res_is_user?(res)
        overwrite_owner_id_method!(res) if owner_is_user?(res)
        normalize_role_ids!(res)
        normalize_permissions!(res)
        res
      end.filter { |res| res.identifier.count('/') <= @absolute_depth + 1 }
    end

    private

    def overwrite_identifier_method!(res)
      user_identifier = user_identifier(res)
      res.define_singleton_method(:identifier) { user_identifier }
    end

    def overwrite_owner_id_method!(res)
      owner = Resource[res.owner_id]
      return if owner.nil?

      owner_full_id = user_full_id(owner)
      res.define_singleton_method(:owner_id) { owner_full_id }
    end

    def normalize_role_ids!(res)
      res.values[:role_ids] = (res.values[:role_ids] || [])
        .map { |role_full_id| normalize_role_id!(role_full_id) }
    end

    def normalize_role_id!(role_full_id)
      return role_full_id unless user?(kind(role_full_id))

      user_full_id(Resource[role_full_id])
    end

    def normalize_permissions!(res)
      res.permissions.each { |perm| normalize_permission!(perm) }
    end

    def normalize_permission!(perm)
      role_full_id = perm[:role_id]
      perm[:role_id] = user_full_id(Resource[role_full_id]) if user?(kind(role_full_id))

      res_full_id = perm[:resource_id]
      perm[:resource_id] = user_full_id(Resource[role_full_id]) if user?(kind(res_full_id))
    end

    def res_is_user?(res)
      user?(res.kind)
    end

    def owner_is_user?(res)
      user?(kind(res.owner_id))
    end

    def policy_for_user(user)
      user_path = user_path(user.identifier)
      return '' if user_path.nil?

      if policy?(kind(user.owner_id))
        owner_identifier = identifier(user.owner_id)
        owner_identifier_dashed = owner_identifier.tr('/', '-')
        return owner_identifier if user_path == owner_identifier_dashed
      end

      find_policy_identifier_for_user(user_path)
    end

    def filter_possible_policies_by_depth(policy_identifiers)
      policy_identifiers.filter do |policy_identifier|
        policy_identifier.values[:identifier].count('/') <= @absolute_depth
      end
    end

    def find_policy_identifier_for_user(user_path)
      @user_to_policy_identifier_cache[user_path] ||= filter_possible_policies_by_depth(
        find_possible_policies(user_path)
      ).first.values[:identifier]
    end

    def find_possible_policies(user_path)
      possible_policies_conditions = "kind(resource_id) = 'policy'
        AND identifier(resource_id) != 'root'
        AND identifier(resource_id) SIMILAR TO ?"
      user_path_policy_pattern = user_path.gsub(%r{[-/]}, '(-|/)')

      Resource.select(Sequel.lit('identifier(resource_id)'))
        .where(Sequel.lit(possible_policies_conditions, user_path_policy_pattern))
        .order(:resource_id)
        .all
    end
  end
end

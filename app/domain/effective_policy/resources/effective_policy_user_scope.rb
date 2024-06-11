# frozen_string_literal: true

module EffectivePolicy
  class UserScopes
    def initialize(
      resource_repository,
      role_id:,
      account:,
      root_pol_user_id_pattern:,
      absolute_depth:
    )
      @resource_repository = resource_repository
      @role_id = role_id
      @account = account
      @root_pol_user_id_pattern = root_pol_user_id_pattern
      @absolute_depth = absolute_depth
    end

    def to_s
      instance_variables.map { |var| "#{var}: #{instance_variable_get(var)}" }.join(", ")
    end

    def fetch_users
      add_conditions_to(select_resources)
        .eager(:annotations)
        .eager(:permissions)
        .eager(owner: proc { |ds| ds.select(:role_id) })
    end

    private

    def select_resources
      @resource_repository.select(
        Sequel.lit('resources.resource_id'),
        Sequel.lit('resources.owner_id'),
        Sequel.function(:array, subselect_role_ids).as(:role_ids)
      )
    end

    def subselect_role_ids
      role_ids_select = "SELECT role_id
        FROM role_memberships
        WHERE member_id = resources.resource_id
          AND ownership = 'f'
          AND kind(member_id) != 'host_factory'
          AND role_id != '!:!:root'"

      Sequel.lit(role_ids_select)
    end

    def select_count_only
      @resource_repository.select(Sequel.function(:count, '1').as(:count))
    end

    def add_conditions_to(select_scope)
      select_scope.from(visible_to_role)
        .where(in_account)
        .where(kind_user)
        .where(within_policy)
    end

    def visible_to_role
      Sequel.function(:visible_resources, @role_id).as(:resources)
    end

    def in_account
      Sequel.lit("account(resources.resource_id) = ?", @account)
    end

    def within_policy
      user_within_policy_conditions = "identifier(resources.resource_id) SIMILAR TO ?"

      Sequel.lit(user_within_policy_conditions, @root_pol_user_id_pattern)
    end

    def kind_user
      Sequel.lit("kind(resources.resource_id) = 'user'")
    end
  end
end

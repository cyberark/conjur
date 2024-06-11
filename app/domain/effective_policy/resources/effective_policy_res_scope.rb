# frozen_string_literal: true

module EffectivePolicy
  class ResourceScopes
    def initialize(
      resource_repository,
      role_id:,
      account:,
      root_pol_id_pattern:,
      absolute_depth:
    )
      @resource_repository = resource_repository
      @role_id = role_id
      @account = account
      @root_pol_id_pattern = root_pol_id_pattern
      @absolute_depth = absolute_depth
    end

    def to_s
      instance_variables.map { |var| "#{var}: #{instance_variable_get(var)}" }.join(", ")
    end

    def count_and_depth_resources
      add_conditions_to(select_count_and_depth)
    end

    def count_annotations
      add_conditions_to(select_count_only)
        .join(:annotations, resource_id: :resource_id)
    end

    def count_permissions
      add_conditions_to(select_count_only)
        .join(:permissions, resource_id: :resource_id)
    end

    def fetch_resources
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
              AND identifier(role_id) SIMILAR TO ?
              AND kind(member_id) != 'host_factory'
              AND res_depth(role_id) <= ?
              AND role_id != '!:!:root'"

      Sequel.lit(role_ids_select, @root_pol_id_pattern, @absolute_depth.to_s)
    end

    def select_count_and_depth
      @resource_repository.select(
        Sequel.function(:coalesce, Sequel.lit('max(res_depth(resources.resource_id))'), 0).as(:depth),
        Sequel.function(:count, '1').as(:count)
      )
    end

    def select_count_only
      @resource_repository.select(Sequel.function(:count, '1').as(:count))
    end

    def add_conditions_to(select_scope)
      select_scope.from(visible_to_role)
        .where(in_account)
        .where(in_policy)
        .where(kind_not_user)
        .where(max_depth)
    end

    def visible_to_role
      Sequel.function(:visible_resources, @role_id).as(:resources)
    end

    def in_account
      Sequel.lit("account(resources.resource_id) = ?", @account)
    end

    def in_policy
      Sequel.lit("identifier(resources.resource_id) SIMILAR TO ?", @root_pol_id_pattern)
    end

    def kind_not_user
      Sequel.lit("kind(resources.resource_id) != 'user'")
    end

    def max_depth
      Sequel.lit("res_depth(resources.resource_id) <= #{@absolute_depth}")
    end
  end
end

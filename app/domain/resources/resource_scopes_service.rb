# frozen_string_literal: true

require 'singleton'

module Resources
  class ResourceScopesService
    include Singleton
    include Domain
    def initialize(
      res_repo: ::Resource
    )
      @res_repo = res_repo
    end

    def paginate_scope(paging, base_scope)
      paging_scope = base_scope
      paging_scope = paging_scope.limit(paging.limit) if paging.limit?
      paging_scope = paging_scope.offset(paging.offset) if paging.offset?
      paging_scope
    end

    def resources_to_del_scope(account, identifier)
      @res_repo.select(
        Sequel.lit('resources.resource_id'),
        Sequel.lit('resources.owner_id')
      ).from(Sequel.lit("resources").as(:resources))
        .where(in_account(account))
        .where(in_policy(root_pol_id_pattern(identifier)))
        .where(kind_not_user)
    end

    def visible_resources_scope(account, role_id, identifier)
      @res_repo.select(
        Sequel.lit('resources.resource_id'),
        Sequel.lit('resources.owner_id')
      ).from(visible_to_role(role_id))
        .where(role_allowed_to_read?(role_id))
        .where(parent_branch_not_root)
        .where(in_account(account))
        .where(in_policy(root_pol_id_pattern(identifier)))
        .where(parent_branch_exists)
        .where(kind_policy)
        .order(:resource_id)
    end

    private

    def role_allowed_to_read?(role_id)
      Sequel.function(:is_role_allowed_to, role_id, 'read', :resource_id)
    end

    def parent_branch_exists
      Sequel.lit(" EXISTS (SELECT 1 FROM resources r WHERE r.resource_id=regexp_replace(resources.resource_id, '/[^/]*$', '')) ")
    end

    def parent_branch_not_root
      Sequel.lit(" identifier(resources.resource_id) != 'root'")
    end

    def visible_to_role(role_id)
      Sequel.function(:visible_resources, role_id).as(:resources)
    end

    def in_account(account)
      Sequel.lit("account(resources.resource_id) = ?", account)
    end

    def in_policy(root_pol_id_pattern)
      Sequel.lit("identifier(resources.resource_id) SIMILAR TO ?", root_pol_id_pattern)
    end

    def kind_policy
      Sequel.lit("kind(resources.resource_id) = 'policy'")
    end

    def kind_not_user
      Sequel.lit("kind(resources.resource_id) != 'user'")
    end
  end
end

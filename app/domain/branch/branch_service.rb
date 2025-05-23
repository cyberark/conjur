# frozen_string_literal: true

require 'singleton'
require_relative 'domain'

module Domain
  class BranchService
    include Singleton
    include Domain
    def initialize(
      owner_service: OwnerService.instance,
      ann_service: AnnotationService.instance,
      res_scopes_service: ResourceScopesService.instance,
      res_repo: ::Resource,
      role_repo: ::Role,
      role_mbrship_repo: ::RoleMembership,
      secret_repo: ::Secret
    )
      @owner_service = owner_service
      @ann_service = ann_service
      @res_scopes_service = res_scopes_service
      @res_repo = res_repo
      @role_repo = role_repo
      @role_mbrship_repo = role_mbrship_repo
      @secret_repo = secret_repo
    end

    def check_parent_branch_exists(account, identifier)
      return if root?(identifier)

      parent_identifier = parent_identifier(identifier)
      read_branch(account, parent_identifier)
    end

    def create_branch(account, branch)
      branch_id = full_id(account, 'policy', branch.identifier)
      owner_id = res_owner_id(account, branch.branch, branch.owner)
      policy_id = full_id(account, 'policy', res_identifier(branch.branch))

      # policy
      policy = @res_repo.create(
        resource_id: branch_id,
        owner_id: owner_id,
        policy_id: policy_id
      ).save

      # role
      @role_repo.create(role_id: branch_id, policy_id: policy_id).save

      # role memberships
      @role_mbrship_repo.create(
        role_id: branch_id,
        member_id: owner_id,
        policy_id: policy_id,
        admin_option: true, ownership: true
      ).save

      # annotations
      branch.annotations.each do |a_key, a_value|
        @ann_service.create_ann(branch_id, a_key, a_value, policy_id).save
      end

      Branch.from_model(policy)
    end

    def update_branch(account, branch_up_part, identifier)
      policy = read_branch_pol(account, identifier)
      raise Exceptions::RecordNotFound, full_id(account, 'branch', identifier) if policy.nil?

      update_owner(account, policy, branch_up_part.owner) if branch_up_part.owner.set?
      update_annotations(policy, branch_up_part.annotations) unless branch_up_part.annotations.empty?
      read_branch(account, policy.identifier)
    end

    def read_branch(account, identifier)
      policy = read_branch_pol(account, identifier)
      raise Exceptions::RecordNotFound, full_id(account, 'branch', identifier) if policy.nil?

      Branch.from_model(policy)
    end

    def check_branch_not_conflict(account, identifier)
      policy = read_branch_pol(account, identifier)
      raise Exceptions::RecordExists.new('Branch', full_id(account, 'branch', identifier)) if policy
    end

    def read_branches(account, role_id, paging, identifier)
      base_scope = @res_scopes_service.visible_branches_scope(account, role_id, identifier)
      total_count = base_scope.count

      branches = @res_scopes_service.paginate_scope(paging, base_scope)
        .eager(owner: proc { |ds| ds.select(:role_id) })
        .eager(:annotations)
        .all
        .map { |pol| Branch.from_model(pol) }

      # result to be returned
      { branches: branches,
        count: total_count }
    end

    def delete_branch(account, role, identifier)
      resources = @res_scopes_service.resources_to_del_scope(account, identifier)
        .order(Sequel.lit("length(resource_id)").desc)
        .all

      resources.each do |res|
        raise Exceptions::RecordNotFound, full_id(account, 'branch', res.identifier) unless role.allowed_to?(:update, res)

        res.secrets.each(&:delete)
        res.annotations.each(&:delete)
        res.delete
      end
    end

    private

    def read_branch_pol(account, identifier)
      pol_id = full_id(account, 'policy', res_identifier(identifier))
      @res_repo[pol_id]
    end

    def update_annotations(policy, annotations)
      merged_anns = get_saved_annotations(policy).merge(annotations)
      merged_anns.each do |ann_key, ann_value|
        @ann_service.upsert_ann(policy.id, policy.policy_id, ann_key, ann_value)
      end
    end

    def get_saved_annotations(policy)
      Annotations.from_model(policy.annotations)
        .to_h
        .deep_transform_keys(&:to_sym)
    end

    def update_owner(account, policy, owner)
      parent = parent_identifier(policy.identifier)
      owner_id = res_owner_id(account, parent, owner)
      policy.update(owner_id: owner_id).save
    end

    def res_owner_id(account, parent_identifier, owner)
      res_owner = @owner_service.resource_owner(parent_identifier, owner)
      full_id(account, res_owner.kind, res_owner.id)
    end
  end
end

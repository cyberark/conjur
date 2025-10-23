# frozen_string_literal: true

require 'singleton'

module Memberships
  class MembershipService
    include Singleton
    include Domain
    include Logging

    def initialize(
      owner_service: Branches::OwnerService.instance,
      annotation_service: Annotations::AnnotationService.instance,
      res_service: Resources::ResourceService.instance,
      res_scopes_service: Resources::ResourceScopesService.instance,
      role_repo: ::Role,
      role_membership_repo: ::RoleMembership,
      secret_repo: ::Secret,
      logger: Rails.logger
    )
      @owner_service = owner_service
      @annotation_service = annotation_service
      @res_service = res_service
      @res_scopes_service = res_scopes_service
      @role_repo = role_repo
      @role_membership_repo = role_membership_repo
      @secret_repo = secret_repo
      @logger = logger
    end

    def add_member(role, account, group_identifier, member)
      log_debug({ role: role, account: account, group_identifier: group_identifier, member: member })
      check_group_is_not_own_member(group_identifier, member)

      group_res = @res_service.read_res(role, account, 'group', group_identifier)
      member_res = read_member_res(role, account, member)
      check_membership_not_exist(group_res, member_res)

      membership_db = create_membership_db(group_res, member_res)
      Memberships::Member.from_model(membership_db)
    rescue => e
      @logger.error("Failed to add member: #{e.message}")
      raise e
    end

    def remove_member(role, account, group_identifier, member)
      log_debug({ role: role, account: account, group_identifier: group_identifier, member: member })

      group_res = @res_service.read_res(role, account, 'group', group_identifier)
      member_res = read_member_res(role, account, member)
      membership_db = fetch_membership_db(group_res, member_res)
      if membership_db.nil?
        raise Errors::Group::ResourceNotMember.new(member.id, member.kind, domain_id(group_identifier))
      end

      membership_db.destroy
      Memberships::Member.from_model(membership_db)
    end

    private

    def read_member_res(role, account, member)
      @res_service.read_res(role, account, member.kind, member.id)
    rescue Exceptions::RecordNotFound => e
      raise ApplicationController::InvalidParameter, e.message
    end

    def check_group_is_not_own_member(group_identifier, member)
      return if member.kind != "group" || group_identifier != member.id

      raise Errors::Conjur::ParameterValueInvalid.new("Member ID", "The '#{group_identifier}' group cannot be a member of itself")
    end

    def check_membership_not_exist(group_res, member_res)
      membership = fetch_membership_db(group_res, member_res)
      return if membership.nil?

      raise Errors::Group::DuplicateMember.new(domain_id(identifier(member_res.id)), kind(member_res.id), group_res.id)
    end

    def create_membership_db(group_res, member_res)
      @role_membership_repo.create(
        role_id: group_res.resource_id,
        member_id: member_res.resource_id,
        admin_option: false,
        ownership: false,
        policy_id: group_res.policy_id
      ).save
    end

    def fetch_membership_db(group_res, member_res)
      @role_membership_repo.where(
        role_id: group_res.resource_id,
        member_id: member_res.resource_id,
        ownership: false
      ).first
    end
  end
end

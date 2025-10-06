# frozen_string_literal: true

require 'singleton'

module Resources
  class ResourceService
    include Singleton
    include Domain
    include Logging

    def initialize(
      res_repo: ::Resource,
      role_repo: ::Role,
      logger: Rails.logger
    )
      @res_repo = res_repo
      @role_repo = role_repo
      @logger = logger
    end

    def save_res(policy_id, owner_id, resource_id)
      @res_repo.create(
        resource_id: resource_id,
        owner_id: owner_id,
        policy_id: policy_id
      ).save
    end

    # Fetching a resource by id and checking its visibility to the given role
    # @raise Exceptions::RecordNotFound if nil or not visible
    # @return ::Resource
    def read_res(role, account, kind, identifier)
      resource = fetch_res(account, kind, identifier)
      return resource if resource&.visible_to?(role)

      raise Exceptions::RecordNotFound, full_id(account, kind, identifier)
    end

    # Fetching a resource by id and checking its nullability
    # @raise Exceptions::RecordNotFound if nil
    # @return ::Resource
    def get_res(account, kind, identifier)
      resource = fetch_res(account, kind, identifier)
      return resource unless resource.nil?

      raise Exceptions::RecordNotFound, full_id(account, kind, identifier)
    end

    # Fetching a resource by id - can return nil if not found
    # @return ::Resource or nil
    def fetch_res(account, kind, identifier)
      resource_id = full_id(account, kind, res_identifier(identifier))
      Resource[resource_id]
    end

    def check_res_not_conflict(account, kind, identifier)
      resource = fetch_res(account, kind, identifier)

      raise Exceptions::RecordExists.new(kind, identifier) if resource
    end

    def read_and_auth_policy(role, action, account, identifier)
      log_debug("role = #{role.id}, action = #{action},
        account = #{account}, identifier = #{identifier}")

      policy =  read_res(role, account, 'policy', identifier)
      authorize_res(role, action, policy)
      policy
    end

    def authorize_res(role, privilege, resource)
      return if role.allowed_to?(privilege, resource)

      @logger.info(
        Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
          role.role_id, privilege, resource.resource_id
        )
      )
      raise Exceptions::Forbidden
    end
  end
end

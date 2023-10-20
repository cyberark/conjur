# frozen_string_literal: true

module RBAC
  class Permission
    def initialize(role_library: Role, resource_library: Resource)
      @role_library = role_library
      @resource_library = resource_library
    end

    def permitted?(role_id:, resource_id:, privilege:)
      role = @role_library[role_id]
      resource = @resource_library[resource_id]

      return true if role.present? && role.allowed_to?(privilege, resource)

      raise(
        Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
          [role.kind, role.identifier].join('/'),
          privilege,
          resource.id
        )
      )
    end
  end
end

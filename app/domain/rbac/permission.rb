# frozen_string_literal: true

module RBAC
  class Permission
    def initialize(resource_library: ::Resource, role_library: ::Role)
      @resource_library = resource_library
      @role_library = role_library

      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    # Accepts both `role` and `role_id` to provide flexibility of lookup.
    # Note that `role` is taken ahead of `role_id`.
    def permitted?(privilege:, resource_id: nil, resource: nil, role: nil, role_id: nil)
      resource ||= @resource_library[resource_id]

      unless resource.present?
        return @failure.new(
          "Resource '#{resource_id}' was not found",
          status: :unauthorized,
          exception: Errors::Conjur::RequiredResourceMissing.new(resource_id)
        )
      end

      # Lookup role if the role ID was provided (and the role was not)
      role ||= @role_library[role_id]

      if role.present? && role.allowed_to?(privilege, resource)
        @success.new(role)
      else

        @failure.new(
          role || role_id,
          status: :forbidden,
          exception: Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
            [role.try(:kind), role.try(:identifier)].join('/'),
            privilege,
            resource.try(:id)
          )
        )
      end
    end
  end
end

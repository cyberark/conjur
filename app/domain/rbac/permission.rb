# frozen_string_literal: true

module RBAC
  class Permission
    def initialize(resource_library: ::Resource)
      @resource_library = resource_library

      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def permitted?(role:, resource_id:, privilege:)
      resource = @resource_library[resource_id]

      unless resource.present?
        return @failure.new(
          "Resource '#{resource_id}' was not found",
          status: :unauthorized,
          exception: Errors::Conjur::RequiredResourceMissing.new(resource_id)
        )
      end

      # binding.pry
      if role.present? && role.allowed_to?(privilege, resource)
        @success.new(role)
      else
        @failure.new(
          role,
          status: :forbidden,
          exception: Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
            [role.try(:kind), role.try(:identifier)].join('/'),
            privilege,
            resource_id
          )
        )
      end
    end
  end
end

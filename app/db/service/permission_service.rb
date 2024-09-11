# frozen_string_literal: true

module DB
  module Service

    class PermissionService < AbstractService

      def create_permission(resource_id, privilege, role_id, policy_id)
        db_object = ::Permission.create(
          resource_id: resource_id,
          privilege: privilege,
          role_id: role_id,
          policy_id: policy_id
        )

        # We want to make sure that db_object is not nil. If this log appears we need to throw erros
        if db_object.nil?
          logger.error("Permission creation failed for resource_id: #{resource_id} privilege: #{privilege} role_id: #{role_id} policy_id: {policy_id}")
        end

        ::PermissionEventInput.instance.send_event(::PermissionEventInput::CREATED, db_object)
      end
    end
  end
end

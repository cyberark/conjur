# frozen_string_literal: true

module DB
  module Service

    class PermissionService < AbstractService

      # Create a permission
      # @param [String] resource_id
      # @param [String] privilege
      # @param [String] role_id
      # @param [String] policy_id
      # @return [Permission] 
      def create_permission(resource_id, privilege, role_id, policy_id)
        db_object = ::Permission.create(
          resource_id: resource_id,
          privilege: privilege,
          role_id: role_id,
          policy_id: policy_id
        )

        # We want to make sure that db_object is not nil. If this log appears we need to throw erros
        if db_object.nil?
          @logger.error("Permission creation failed for resource_id: #{resource_id} privilege: #{privilege} role_id: #{role_id} policy_id: {policy_id}")
        end
        ::PermissionEventInput.instance.send_event(::PermissionEventInput::CREATED, db_object)
        db_object
      end

      # Delete a permission
      # @param [String] resource_id
      # @param [String] privilege
      # @param [String] role_id
      # @param [String] policy_id
      # @return [void]
      # @note if resource_id is nil, this method will return without doing anything
      def delete_permission(resource_id, privilege = nil, role_id = nil, policy_id = nil)
        return if resource_id.nil?

        db_object = ::Permission[{ resource_id: resource_id, privilege: privilege, role_id: role_id, policy_id: policy_id }.compact]

        if db_object.nil?
          @logger.error("Permission deletion failed for resource_id: #{resource_id} privilege: #{privilege} role_id: #{role_id}")
        else
          db_object.destroy
          ::PermissionEventInput.instance.send_event(::PermissionEventInput::DELETED, db_object)
        end
      end

    end
  end
end

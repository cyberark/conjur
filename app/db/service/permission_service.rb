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
      # @note user should  validate the input before calling this method
      def create_permission(resource_id, privilege, role_id, policy_id)
        db_object = ::Permission.create(
          resource_id: resource_id,
          privilege: privilege,
          role_id: role_id,
          policy_id: policy_id
        )

        # We want to make sure that db_object is not nil. If this log appears, it means that the permission creation failed. 
        # This is a critical error and should be investigated. And we should throw an exception here.
        if db_object.nil?
          @logger.error("Permission creation failed for resource_id: #{resource_id} privilege: #{privilege} role_id: #{role_id} policy_id: {policy_id}")
          return
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
      # @note if one of the parameters are nil, this method will return without doing anything
      def delete_permission(resource_id, privilege, role_id, policy_id)
        # If permission is called like: ::Permission[{}] it will return the first record in the table.
        # which is unexpected. So we need to check if the required fields are nil, log a warning and return
        if resource_id.nil? || privilege.nil? || role_id.nil?
          @logger.warn("Permission deletion failed for resource_id: #{resource_id} privilege: #{privilege} role_id: #{role_id}. One of the required fields is nil.")
          return
        end

        db_object = ::Permission[{ resource_id: resource_id, privilege: privilege, role_id: role_id, policy_id: policy_id }.compact]

        if db_object.nil?
          @logger.warn("Permission deletion failed for resource_id: #{resource_id} privilege: #{privilege} role_id: #{role_id}")
          return
        end
        db_object.destroy
        ::PermissionEventInput.instance.send_event(::PermissionEventInput::DELETED, db_object)
      end

    end
  end
end

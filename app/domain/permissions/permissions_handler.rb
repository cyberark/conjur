module PermissionsHandler
  include ParamsValidator
  include ResourcesHandler

  def add_permissions(resources_privileges, secret_id, policy_id)
    resources_privileges.each do |resource_id, privileges|
      privileges.each do |p|
        ::Permission.create(
          resource_id: secret_id,
          privilege: p,
          role_id: resource_id,
          policy_id: policy_id
        )
      end
    end
  end

  def delete_resource_permissions(resource)
    Permission.where(resource_id: resource.id).delete
  end

  def get_permissions(resource)
    permissions = Permission.where(resource_id: resource.id).group(:role_id)
                    .select(:role_id, Sequel.function(:array_agg, :privilege).as(:privileges))
    permissions = permissions.map do |permission|
      role_parts = permission[:role_id].split(':')
      {
        subject: {
          id: role_parts[2],
          kind: role_parts[1]
        },
        privileges: permission[:privileges].to_a
      }
    end
    # Return empty list if no permissions defined
    unless permissions
      permissions = []
    end
    permissions
  end

  # Validates the permissions section of the request is valid and returns a map between the resource id and its privileges
  def validate_permissions(permissions, allowed_privilege)
    resources_privileges = {}
    permissions.each do |permission|
      # Validate subject field exists
      subject = permission[:subject]
      raise Errors::Conjur::ParameterMissing, "Privilege Subject" unless subject

      data_fields = {
        kind: {
          field_info: {
            type: String,
            value: subject[:kind]
          },
          validators: [
            method(:validate_field_required),
            method(:validate_field_type),
            lambda { |field_name, field_info| validate_resource_kind(field_info[:value], subject[:id], %w[user host group]) }]
        },
        id: {
          field_info: {
            type: String,
            value: subject[:id]
          },
          validators: [method(:validate_field_required), method(:validate_field_type), method(:validate_path)]
        },
        privileges: {
          field_info: {
            type: String,
            value: permission[:privileges]
          },
          validators: [
            method(:validate_field_required),
            lambda { |field_name, field_info| validate_privilege(subject[:id], field_info[:value], allowed_privilege) }
          ]
        }
      }
      validate_data_fields(data_fields)

      # Validate subject resource exists
      resource_id = full_resource_id(subject[:kind], subject[:id])
      raise Exceptions::RecordNotFound, resource_id unless Resource[resource_id]
      # Update resource privileges
      resources_privileges[resource_id] = permission[:privileges]
    end

    resources_privileges
  end
end
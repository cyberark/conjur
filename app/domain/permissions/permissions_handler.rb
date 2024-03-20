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
    # Return empty list if no annotations after filter
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
      # Validate all fields in subject exists
      data_fields = {
        kind: String,
        id: String
      }
      validate_required_data(subject, data_fields.keys)
      # Validate subject kind value
      validate_subject_kind(subject[:kind],subject[:id])
      # Validate subject resource exists
      resource_id = full_resource_id(subject[:kind], subject[:id])
      raise Exceptions::RecordNotFound, resource_id unless Resource[resource_id]
      # Validate privileges
      raise Errors::Conjur::ParameterMissing, "Privileges" unless permission[:privileges]
      validate_privilege(resource_id, permission[:privileges], allowed_privilege)
      # Update resource privileges
      resources_privileges[resource_id] = permission[:privileges]
    end

    resources_privileges
  end

  private
  def validate_privilege(resource_id, privileges, allowed_privilege)
    privileges.each do |privilege|
      unless allowed_privilege.include?(privilege)
        raise Errors::Conjur::ParameterValueInvalid.new("Resource #{resource_id} privileges", "Allowed values are [read execute update]")
      end
    end
  end

  def validate_subject_kind(resource_kind, resource_id)
    allowed_kind = %w[user host group]
    unless allowed_kind.include?(resource_kind)
      raise Errors::Conjur::ParameterValueInvalid.new("Resource #{resource_id} kind", "Allowed values are [user host group]")
    end
  end
end
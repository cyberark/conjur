module PermissionsHandler
  include ParamsValidator
  include ResourcesHandler

  def add_permissions(resource, policy, permissions)

  end

  # Validates the permissions section of the request is valid and returns a map between the resource id and its privileges
  def validate_permissions(permissions)
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
      resource_id = resource_id(subject[:kind],subject[:id])
      raise Exceptions::RecordNotFound, resource_id unless Resource[resource_id]
      # Validate privileges
      raise Errors::Conjur::ParameterMissing, "Privileges" unless permission[:privileges]
      validate_privilege(resource_id, permission[:privileges])
      # Update resource privileges
      resources_privileges[resource_id] = permission[:privileges]
    end

    resources_privileges
  end

  private
  def validate_privilege(resource_id, privileges)
    allowed_privilege = %w[read execute update]
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
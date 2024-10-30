# frozen_string_literal: true

# A factory for creating role and resource DTO structs

module DataObjects

  RoleDTO = Struct.new(
    'RoleDTO',
    :identifier,
    :id,
    :type,
    :owner,
    :policy,
    :permissions,
    :annotations,
    :members,
    :memberships,
    :restricted_to
  ) do
  end

  ResourceDTO = Struct.new(
    'ResourceDTO',
    :identifier,
    :id,
    :type,
    :owner,
    :policy,
    :permitted,
    :annotations
  ) do
  end

  class DataValidator

    def validate_fields(db_row)
      # policy_id does not exist on root / admin user resources
      # (e.g. is nullable)
      required_fields = %w[resource_id owner_id]
      required_fields.each do |field|
        unless db_row.key?(field.to_s) || db_row.key?(field.to_sym)
          raise ArgumentError, "#{field} is required, but is missing"
        end
        if db_row[field.to_s].nil? && db_row[field.to_sym].nil?
          raise ArgumentError, "#{field} is required, but the supplied value is nil"
        end
      end
    end

    def validate(db_row)
      validate_fields(db_row)
    end

  end

  class DTOFactory
    ROLE_TYPES = %w[group host layer policy user]
    RESOURCE_TYPES = %w[variable webservice]

    def self.create_DTO_from_hash(db_row)
      dv = DataValidator.new
      dv.validate(db_row)

      identifier = db_row[:resource_id]
      _, type, id = db_row[:resource_id].split(':')
      owner = db_row[:owner_id]
      policy = db_row[:policy_id]
      members = if db_row.key?(:members)
        db_row[:members].map { |memb_hash| memb_hash[:member_id] }
      else
        []
      end

      memberships = if db_row.key?(:memberships)
        db_row[:memberships].map { |ship_hash| ship_hash[:role_id] }
      else
        []
      end

      restricted_to = if db_row.key?(:credentials)
        db_row[:credentials].map { |cred_hash| cred_hash[:restricted_to] }.flatten
      else
        []
      end

      annotations = if db_row.key?(:annotations)
        Hash[db_row[:annotations].map { |ann_hash| [ann_hash[:name], ann_hash[:value]] }]
      else
        {}
      end

      permissions = if db_row.key?(:permissions)
        privilege_keys = db_row[:permissions].map { |perm| perm[:privilege] }.uniq
        resources = privilege_keys.map do |priv|
          db_row[:permissions].filter {|perm| perm[:privilege] == priv }.map { |x| x[:resource_id] }
        end
        Hash[privilege_keys.zip(resources)]
      else
        {}
      end

      permitted = if db_row.key?(:permitted)
        privilege_keys = db_row[:permitted].map { |perm| perm[:privilege] }.uniq
        roles = privilege_keys.map do |priv|
          db_row[:permitted].filter {|perm| perm[:privilege] == priv }.map { |x| x[:role_id] }
        end
        Hash[privilege_keys.zip(roles)]
      else
        {}
      end

      if ROLE_TYPES.include?(type)
        dto = RoleDTO.new(
          identifier: identifier,
          id: id,
          type: type,
          owner: owner,
          policy: policy,
          permissions: permissions,
          annotations: annotations,
          members: members,
          memberships: memberships,
          restricted_to: restricted_to
        )
      elsif RESOURCE_TYPES.include?(type)
        dto = ResourceDTO.new(
          identifier: identifier,
          id: id,
          type: type,
          owner: owner,
          policy: policy,
          permitted: permitted,
          annotations: annotations
        )
      else
        raise ArgumentError, "Problem in data: type is not recognized: #{type}"
      end

      dto
    end

    def self.create_DTO(db_row)
      create_DTO_from_hash(db_row)
    end

    def self.create_DTOs(rows)
      rows.map { |row| create_DTO(row) }
    end

  end
end

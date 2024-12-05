# frozen_string_literal: true

# A factory for creating role and resource DTO structs

module DataObjects

  SensitivePrimitive = Struct.new(
    'SensitivePrimitive',
    :identifier,
    :type
  )

  Role = Struct.new(
    'Role',
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

  Resource = Struct.new(
    'Resource',
    :identifier,
    :id,
    :type,
    :owner,
    :policy,
    :permitted,
    :annotations
  ) do
  end

  class PrimitiveFactory
    ROLE_TYPES = %w[group host layer policy user].freeze
    RESOURCE_TYPES = %w[variable webservice].freeze

    # By default, either:
    # 1. A primitive is completely masked if not present in visible_resources
    #    (SensitivePrimitive is returned)
    # 2. If present in visible_resources, its properties primitive are masked
    #    if not present in visible_resources (Role or Resource is returned)
    #
    # When @is_sensitive is false, a Role or Resource is returned without any
    # fields masked.
    def initialize(
      is_sensitive: true,
      visible_resources: {},
      logger: Rails.logger
      )
      @is_sensitive = is_sensitive
      @visible_resources = visible_resources
      @logger = logger
    end

    def from_hashes(hashes:)
      hashes.map { |item| from_hash(hash: item) }
    end

    def from_hash(hash:)
      validate(hash)

      _, type, id = hash[:resource_id].split(':')

      identifier = censor_resource_id(hash[:resource_id])
      owner = censor_resource_id(hash[:owner_id])
      policy = censor_resource_id(hash[:policy_id])
      members = parse_array(hash, :members, :member_id)
      memberships = parse_array(hash, :memberships, :role_id) 
      restricted_to = parse_restricted_to(hash)
      annotations = parse_annotations(hash)
      permissions = parse_permissions(hash)
      permitted = parse_permitted(hash)

      if @is_sensitive && !resource_visible?(hash[:resource_id])
        SensitivePrimitive.new(
          identifier: identifier,
          type: type
        )
      elsif ROLE_TYPES.include?(type)
        Role.new(
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
        Resource.new(
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
    end

    private

    def validate(hash)
      required_fields = %w[resource_id owner_id]
      required_fields.each do |field|
        unless hash.key?(field.to_s) || hash.key?(field.to_sym)
          raise ArgumentError, "#{field} is required, but is missing"
        end
        if hash[field.to_s].nil? && hash[field.to_sym].nil?
          raise ArgumentError, "#{field} is required, but the supplied value is nil"
        end
      end
    end

    # Given a resource in the form of a hash, extrapolate the resource_id values
    # from the accessor field and censor them if needed.
    def parse_array(hash, accessor, field)
      if hash.key?(accessor.to_sym) && hash[accessor].respond_to?(:map)
        hash[accessor].map { |x| censor_resource_id(x[field.to_sym]) }
      else
        []
      end
    end

    def parse_restricted_to(hash)
      if hash.key?(:credentials)
        hash[:credentials].map { |item| item[:restricted_to] }.flatten
      else
        []
      end
    end

    def parse_annotations(hash)
      if hash.key?(:annotations)
        Hash[hash[:annotations].map { |annotation| [annotation[:name], annotation[:value]] }]
      else
        {}
      end
    end

    def parse_permissions(hash)
      if hash.key?(:permissions)
        privilege_keys = hash[:permissions].map { |perm| perm[:privilege] }.uniq
        resources = privilege_keys.map do |priv|
          hash[:permissions].filter {|perm| perm[:privilege] == priv }.map do |x|
            censor_resource_id(x[:resource_id]) 
          end
        end
        Hash[privilege_keys.zip(resources)]
      else
        {}
      end
    end

    def parse_permitted(hash)
      if hash.key?(:permitted)
        privilege_keys = hash[:permitted].map { |perm| perm[:privilege] }.uniq
        roles = privilege_keys.map do |priv|
          hash[:permitted].filter {|perm| perm[:privilege] == priv }.map do |x|
            censor_resource_id(x[:role_id])
          end
        end
        Hash[privilege_keys.zip(roles)]
      else
        {}
      end
    end

    def resource_visible?(resource_id)
      @visible_resources[resource_id] == true
    end

    # When this primitive is sensitive, mask the given id if it's
    # not visible.
    def censor_resource_id(resource_id)
      return resource_id if resource_id.nil? || resource_id.empty?
      return resource_id unless @is_sensitive

      account, type, id = resource_id.split(':')
      id = resource_visible?(resource_id) ? id : '[REDACTED]'
      "#{account}:#{type}:#{id}"
    end
  end
end

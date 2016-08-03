class Resource < Sequel::Model
  unrestrict_primary_key
  
  one_to_many :permissions, reciprocal: :resource
  one_to_many :annotations, reciprocal: :resource
  one_to_many :secrets,     reciprocal: :resource, order: :counter
  many_to_one :owner, class: :Role
  
  alias id resource_id
  
  def kind
    id.split(":", 3)[1]
  end
  
  def identifier
    id.split(":", 3)[2]
  end
  
  def as_json options = {}
    super(options).tap do |response|
      # In case
      response.delete("secrets")
      
      response["id"] = response.delete("resource_id")
      response["owner"] = response.delete("owner_id")
      response["permissions"] = self.permissions.as_json
      response["annotations"] = self.annotations.as_json
    end
  end

  class << self
    def make_full_id id, account
      Role.make_full_id id, account
    end
  end
  
  dataset_module do
    # Filter out records based on:
    # @param kind [String] - chooses just resources of this kind
    # @param owner [Role] - owned by this role or one of its ancestors
    def search kind: nil, owner: nil, offset: nil, limit: nil
      scope = self
      # Filter by kind
      scope = scope.where("(?)[2] = ?", ::Sequel.function(:regexp_split_to_array, :resource_id, ':'), kind) if kind
      
      # Filter by owner
      if owner
        owners = Resource.from(::Sequel.function(:all_roles, owner.id)).select(:role_id)
        scope = scope.where owner_id: owners
      end

      if offset || limit
        scope = scope.order(:resource_id).limit(
          (limit || 10).to_i,
          (offset || 0).to_i
        )
      end

      scope
    end
  end

  def role
    Role[id] or raise "Role not found for #{id}"
  end

  def permit privilege, role, options = {}
    options[:privilege] = privilege
    options[:role] = role
    options[:grantor] ||= owner
    add_permission options
  end
  
  # Truncate secrets beyond the configured limit.
  def enforce_secrets_version_limit
    if ( version_count = Sequel::Model(:resources).
      select{ Sequel.function(:count, :resource_id) }.
        join(:secrets, [ :resource_id ]).
        where(resource_id: self.resource_id).
        first[:count] ) > secrets_version_limit
      secrets[0...version_count - secrets_version_limit].map(&:destroy)
    end
  end
end

class Resource < Sequel::Model
  unrestrict_primary_key
  
  one_to_many :permissions, reciprocal: :resource
  one_to_many :annotations, reciprocal: :resource
  one_to_many :secrets,     reciprocal: :resource
  many_to_one :owner, class: :Role
  
  alias id resource_id
  
  def as_json options = {}
    super(options).tap do |response|
      # In case
      response.delete("secrets")
      
      response["id"] = response.delete("resource_id")
      response["permissions"] = self.permissions.as_json
      response["annotations"] = self.annotations.as_json
    end
  end

  class << self
    def make_full_id id
      Role.make_full_id id
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

  def permit privilege, role
    add_permission privilege: privilege, role: role
  end
end

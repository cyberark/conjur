class Resource < Sequel::Model
  unrestrict_primary_key
  
  one_to_many :permissions, reciprocal: :resource
  one_to_many :annotations, reciprocal: :resource
  one_to_many :secrets,     reciprocal: :resource
  many_to_one :owner, class: :Role
  
  plugin :json_id_serializer   
  
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
      scope = scope.where Sequel.function(:kind, :id) => kind if kind

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

  def as_json opts = {}
    super(exclude: [ :secrets, :owner ]).merge('permissions' => permissions.as_json(opts), 'annotations' => annotations.as_json(opts))
  end

  def permit privilege, role
    add_permission privilege: privilege, role: role
  end
end

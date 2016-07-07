class ResourcesController < RestController
  before_filter :find_resource, only: [ :show, :permitted_roles, :check_permission ]

  # ResourceItem = Struct.new(:id, :owner_id, :permissions, :annotations)
    
  def index
    ids = params.delete(:ids)
    options = params.slice(:kind, :limit, :offset).symbolize_keys
    if params[:owner]
      options[:owner] = Role[roleid_from_username(params[:owner])] || raise(IndexError)
    end
    
    scope = Resource.search(options)
    result = if ids
      scope.select(:resources.resource_id).all
    else
      scope.select(:resources.*).eager(:annotations).eager(:permissions).all
    end
  
    render json: result
  end
  
  def show
    render json: @resource
  end
  
  def permitted_roles
    privilege = params[:permission]
    raise ArgumentError, "permission" unless privilege
    render json: Role.that_can(privilege, @resource).map {|r| r.id}
  end

    
  # Implements the use case "check MY permission on some resource", where "me" is defined as the +current_role+.
  def check_permission
    privilege = params[:privilege]
    raise ArgumentError, "privilege" unless privilege
    if current_role.allowed_to?(privilege, @resource)
      head :no_content
    else
      head :not_found
    end
  end
  
  protected
  
  def resource_id
    [ params[:account], params[:kind], params[:identifier] ].compact.join(":")
  end

  def find_resource
    @resource = Resource[resource_id]
    raise IndexError unless @resource
  end
end
class ResourcesController < RestController
  include FindResource
  
  before_filter :find_resource, only: [ :show, :permitted_roles, :check_permission ]
    
  def index
    options = params.slice(:kind, :limit, :offset).symbolize_keys
    if params[:owner]
      ownerid = Role.make_full_id(params[:owner], account)
      options[:owner] = Role[ownerid] or raise Exceptions::RecordNotFound, ownerid
    end
    
    scope = Resource.search(params[:account], options)
    result = scope.select(:resources.*).eager(:annotations).eager(:permissions).eager(:secrets).eager(:policy_versions).all
  
    render json: result
  end
  
  def show
    render json: @resource
  end
  
  def permitted_roles
    privilege = params[:privilege] || params[:permission]
    raise ArgumentError, "privilege" unless privilege
    render json: Role.that_can(privilege, @resource).map {|r| r.id}
  end

  # Implements the use case "check MY permission on some resource", where "me" is defined as the +current_user+.
  def check_permission
    privilege = params[:privilege]
    raise ArgumentError, "privilege" unless privilege
    if current_user.allowed_to?(privilege, @resource)
      head :no_content
    else
      head :not_found
    end
  end
end
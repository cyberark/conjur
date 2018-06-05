class ResourcesController < RestController
  include FindResource
  include AssumedRole
  
  before_filter :find_resource, only: [ :show, :permitted_roles, :check_permission ]
  
  def index
    options = params.slice(:account, :kind, :limit, :offset, :search).symbolize_keys
    
    if params[:owner]
      ownerid = Role.make_full_id(params[:owner], account)
      options[:owner] = Role[ownerid] or raise Exceptions::RecordNotFound, ownerid
    end
    
    scope = Resource.visible_to(assumed_role).search options

    result =
      if params[:count] == 'true'
        { count: scope.count('*'.lit) }
      else
        scope.select(:resources.*).
          eager(:annotations).
          eager(:permissions).
          eager(:secrets).
          eager(:policy_versions).
          all
      end
  
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

  # Implements the use case "check permission on some resource",
  # either for the role specified by the query string, or for the
  # +current_user+.
  def check_permission
    privilege = params[:privilege]
    raise ArgumentError, "privilege" unless privilege

    if assumed_role.allowed_to?(privilege, @resource)
      head :no_content
    else
      head :not_found
    end
  end
end

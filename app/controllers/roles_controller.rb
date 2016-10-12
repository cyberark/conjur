class RolesController < RestController
  before_filter :find_role, only: [ :show, :memberships, :check_permission ]

  def show
    render json: @role.as_json.merge(members: @role.memberships)
  end
  
  def memberships
    filter = params[:filter]
    if filter
      filter = Array(filter).map{|id| Role.make_full_id id, account}
    end
    
    render json: @role.all_roles(filter).map(&:role_id)
  end

  def check_permission 
    resource = Resource[resource_id] || Exceptions::RecordNotFound, resource_Id
    privilege = params[:privilege]
    raise ArgumentError, "privilege" unless privilege
    if @role.allowed_to?(privilege, resource)
      head :no_content
    else
      head :not_found
    end   
  end

  protected

  def role_id
    [ params[:account], params[:kind], params[:identifier] ].join(":")
  end
  
  def find_role
    @role = Role[role_id]
    raise Exceptions::RecordNotFound, role_id unless @role
  end
  
  # By default the resource is found in the same account as the account parameter.
  def resource_id
    Resource.make_full_id params[:resource], account
  end
end

class RolesController < RestController
  before_filter :find_role, only: [ :show, :memberships ]

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

  protected

  def role_id
    [ params[:account], params[:kind], params[:identifier] ].join(":")
  end
  
  def find_role
    @role = Role[role_id]
    raise Exceptions::RecordNotFound, role_id unless @role
  end
end

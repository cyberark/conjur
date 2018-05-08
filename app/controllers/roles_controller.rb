class RolesController < RestController
  before_filter :find_role, only: [ :show, :memberships ]

  def show
    render json: @role.as_json.merge(members: @role.memberships)
  end
  
  def memberships
    options = params.slice(:all, :count, :filter, :memberships).symbolize_keys
    
    filter = options[:filter]
    if filter
      filter = Array(filter).map{|id| Role.make_full_id id, account}
    end

    roles = roles_as_dataset(options)

    roles = roles.member_of(filter) if options[:filter]
    
    render json: roles_as_json(roles, options)
  end

  protected

  def role_id
    [ params[:account], params[:kind], params[:identifier] ].join(":")
  end
  
  def find_role
    @role = Role[role_id]
    raise Exceptions::RecordNotFound, role_id unless @role
  end

  def roles_as_dataset(options)
    case
    when options.has_key?(:all)
      @role.all_roles
    when options.has_key?(:memberships)
      @role.memberships_as_member_dataset
    else
      raise "Routing misconfigured, expected params[:all] or params[:membership] to be present"
    end
  end
  
  def roles_as_json(roles, options)
    case
    when options.has_key?(:count)
      { count: roles.count }
    when options.has_key?(:memberships)
      roles
    else
      roles.map(&:role_id)
    end
  end
  
end

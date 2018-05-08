class RolesController < RestController
  before_filter :find_role, only: [ :show, :all_memberships, :direct_memberships ]

  def show
    render json: @role.as_json.merge(members: @role.memberships)
  end

  # Find all role memberships, expanded recursively. If no parameters
  # are given, the role id of each membership is returned.
  #
  # If +params[:filter]+ is given, return (as role ids), the subset of
  # memberships that matches the filter
  
  # If +params[:count]+ is given, return the count of memberships,
  # rather than the memberships themselves
  #
  def all_memberships
    options = membership_options
    
    memberships = with_filter(options) do
      @role.all_roles
    end

    json = render_count(memberships, options) || memberships.map(&:role_id)
    
    render json: json
  end

  # Find all direct memberships, i.e don't recursively expand member
  # roles.
  #
  # For each membership, return the full details of the grant as a
  # JSON object.
  # 
  #
  # +params[:filter]+ and +params[:count]+ are handled as for +#all_memberships+
  #
  def direct_memberships
    options = membership_options
    
    memberships = with_filter(options) do
      @role.memberships_as_member_dataset
    end

    json = render_count(memberships, options) || memberships
    render json: json
  end
  
  protected

  def role_id
    [ params[:account], params[:kind], params[:identifier] ].join(":")
  end
  
  def find_role
    @role = Role[role_id]
    raise Exceptions::RecordNotFound, role_id unless @role
  end

  def membership_options
    @membership_options ||= params.slice(:count, :filter).symbolize_keys
  end
  
  def with_filter(options, &block)
    filter = options[:filter]
    if filter
      filter = Array(filter).map{|id| Role.make_full_id id, account}
    end

    roles = yield

    filter ? roles.member_of(filter) : roles
  end
    
  def render_count(roles, options)
    { count: roles.count } if options.has_key?(:count)
  end
  
end

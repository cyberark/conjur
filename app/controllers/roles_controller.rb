# frozen_string_literal: true

# We intentionally call @feature_flags.enabled? multiple times and don't
# factor it out to make these checks easy to discover.
# :reek:RepeatedConditional
class RolesController < RestController
  include AuthorizeResource

  ROLES_API_EXTENSION_KIND = :roles_api

  before_action :current_user

  def initialize(
    *args,
    extension_repository: Conjur::Extension::Repository.new,
    feature_flags: Rails.application.config.feature_flags,
    **kwargs
  )
    super(*args, **kwargs)

    @feature_flags = feature_flags

    # If role API extensions are enabled, load the registered callbacks
    @extensions = if @feature_flags.enabled?(:roles_api_extensions)
      extension_repository.extension(kind: ROLES_API_EXTENSION_KIND)
    end
  end

  def show
    render(json: role.as_json.merge(members: role.memberships))
  end

  # Find all role memberships, expanded recursively. If no parameters
  # are given, the role id of each membership is returned.
  #
  # If +params[:filter]+ is given, return (as role ids), the subset of
  # memberships that matches the filter
  #
  # If +params[:count]+ is given, return the count of memberships,
  # rather than the memberships themselves
  #
  def all_memberships
    memberships = filtered_roles(role.all_roles, membership_filter)
    render_dataset(memberships) { |dataset| dataset.map(&:role_id) }
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
    memberships = filtered_roles(role.direct_memberships_dataset(filter_params), membership_filter)
    render_result = render_dataset(memberships)
    audit_memberships_success(membership_filter)
    return render_result
  rescue => e
    audit_memberships_failure(membership_filter, e)
    raise e
  end

  # Find all members of this role.
  #
  # For each member, return the full details of the grant as a
  # JSON object
  #
  # +params[:count] returns only the number of members
  # +params[:limit] and [:offset] control the paging
  # +params[:search] returns only the members that match the search string
  # +params[:kind] (array) returns only the members that match the specified kinds
  def members
    members = role.members_dataset(filter_params)
    render_result = render_dataset(members) { |dataset| dataset.result_set(**render_params) }
    audit_list_success
    return render_result
  rescue => e
    audit_list_failure(e)
    raise e
  end

  # Returns a graph of the roles anchored on the current Role
  def graph
    render(json: role.graph)
  end

  # update_member will add or modify an existing role membership
  #
  # This API endpoint exists to manage group entitlements through
  # the UI or other integrations outside of loading a policy.
  #
  # We intentionally call @feature_flags.enabled? multiple times and don't
  # factor it out to make these checks easy to discover.
  # :reek:DuplicateMethodCall
  def add_member
    authorize(:create, policy)

    member_id = params[:member]
    member = Role[member_id]
    raise Exceptions::RecordNotFound, member_id unless member

    if @feature_flags.enabled?(:roles_api_extensions)
      @extensions.call(:before_add_member, role: role, member: member)
    end

    # If membership is already granted, grant_to will return nil.
    # In this case, don't emit an audit record.
    if (membership = role.grant_to(member))
      Audit.logger.log(
        Audit::Event::Policy.new(
          operation: :add,
          subject: Audit::Subject::RoleMembership.new(membership.pk_hash),
          user: current_user,
          client_ip: request.ip
        )
      )
    end

    if @feature_flags.enabled?(:roles_api_extensions)
      @extensions.call(
        :after_add_member,
        role: role,
        member: member,
        membership: membership
      )
    end

    head(:no_content)
  end

  # delete_member will delete a role membership
  #
  # This API endpoint exists to manage group entitlements through
  # the UI or other integrations outside of loading a policy.
  #
  # We intentionally call @feature_flags.enabled? multiple times and don't
  # factor it out to make these checks easy to discover.
  # :reek:DuplicateMethodCall
  def delete_member
    authorize(:update, policy)

    member_id = params[:member]
    membership = role.memberships_dataset.where(member_id: member_id).first
    raise Exceptions::RecordNotFound, member_id unless membership

    if @feature_flags.enabled?(:roles_api_extensions)
      @extensions.call(
        :before_delete_member,
        role: role,
        member: Role[member_id],
        membership: membership
      )
    end

    membership.destroy

    Audit.logger.log(
      Audit::Event::Policy.new(
        operation: :remove,
        subject: Audit::Subject::RoleMembership.new(membership.pk_hash),
        user: current_user,
        client_ip: request.ip
      )
    )

    if @feature_flags.enabled?(:roles_api_extensions)
      @extensions.call(
        :after_delete_member,
        role: role,
        member: Role[member_id],
        membership: membership
      )
    end

    head(:no_content)
  end

  protected

  def policy
    resource.policy
  end

  def resource
    Resource[role_id]
  end

  def role
    @role ||= Role[role_id]
    raise Exceptions::RecordNotFound, role_id unless @role

    return @role
  end

  def role_id
    [ params[:account], params[:kind], params[:identifier] ].join(":")
  end

  def filter_params
    request.query_parameters.slice(:search, :kind).symbolize_keys
  end

  def render_params
    # Rails 5 requires parameters to be explicitly permitted before converting
    # to Hash.  See: https://stackoverflow.com/a/46029524
    allowed_params = %i[limit offset]
    params.permit(*allowed_params)
      .slice(*allowed_params).to_h.symbolize_keys
  end

  def membership_filter
    filter = params[:filter]
    filter = Array(filter).map{ |id| Role.make_full_id(id, account) } if filter
    return filter
  end

  def filtered_roles(roles, filter)
    filter ? roles.member_of(filter) : roles
  end

  def render_dataset(dataset, &block)
    resp = count_only?  ? count_payload(dataset) :
           block_given? ? yield(dataset)         : dataset.all

    render(json: resp)
  end

  def count_only?
    params.key?(:count)
  end

  def count_payload(dataset)
    { count: dataset.count }
  end

  def audit_list_success
    additional_params = %i[account count kind search limit offset]
    options = params.permit(*additional_params).to_h.symbolize_keys
    options[:role] = role_id
    Audit.logger.log(
      Audit::Event::Members.new(
        user_id: current_user.role_id,
        client_ip: request.ip,
        subject: options,
        success: true
      )
    )
  end

  def audit_list_failure(err)
    additional_params = %i[account count search kind limit offset]
    options = params.permit(*additional_params).to_h.symbolize_keys
    options[:role] = role_id
    Audit.logger.log(
      Audit::Event::Members.new(
        user_id: current_user.role_id,
        client_ip: request.ip,
        subject: options,
        success: false,
        error_message: err.message
      )
    )
  end

  def audit_memberships_success(filter)
    additional_params = %i[account count search kind filter]
    options = params.permit(*additional_params).to_h.symbolize_keys
    options[:filter] = filter if filter
    options[:role] = role_id
    Audit.logger.log(
      Audit::Event::Memberships.new(
        user_id: current_user.role_id,
        client_ip: request.ip,
        subject: options,
        success: true
      )
    )
  end

  def audit_memberships_failure(filter, err)
    additional_params = %i[account count search kind filter]
    options = params.permit(*additional_params).to_h.symbolize_keys
    options[:filter] = filter if filter
    options[:role] = role_id
    Audit.logger.log(
      Audit::Event::Memberships.new(
        user_id: current_user.role_id,
        client_ip: request.ip,
        subject: options,
        success: false,
        error_message: err.message
      )
    )
  end

end

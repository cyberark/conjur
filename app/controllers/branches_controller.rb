# frozen_string_literal: true

class BranchesController < V2RestController

  BRANCH_OPTIONAL_PARAMS = [owner: %i[kind id], annotations: {}].freeze

  def initialize(
    *args,
    branch_service: Branches::BranchService.instance,
    owner_service: Branches::OwnerService.instance,
    **kwargs
  )
    super(*args, **kwargs)

    @branch_service = branch_service
    @owner_service = owner_service
  end

  def create
    url_params = permit_create_url_params
    input = permit_create_body_params
    log_debug("url_params = #{url_params}, input = #{input}")

    branch = Branches::Branch.from_input(input)
    log_debug("branch = #{branch}")

    authorize_create_in_parent(branch)
    check_branch_not_conflict(branch)
    check_owner_exists_if_set(branch)

    render(json: create_branch(branch), status: :created)
    audit_action_fine(:create, branch.identifier, audit_payload)
  rescue => e
    audit_action_create_failure(e.message)
    handle_exception(e)
  end

  def show
    url_params = permit_url_params(URL_REQUIRED_PARAMS_IDFR)
    log_debug("url_params = #{url_params}")

    authorize_read(path_identifier)

    render(json: get_branch(path_identifier))
    audit_action_fine(:get)
  rescue => e
    audit_action_failure(:get, e.message)
    handle_exception(e)
  end

  def index
    url_params = permit_url_params(URL_REQUIRED_PARAMS, Paging::PAGING_URL_PARAMS)
    input = url_params.slice(*Paging::PAGING_URL_PARAMS)
    log_debug("url_params = #{url_params}, input = #{input}")

    paging = Paging.new(input)
    log_debug("paging = #{paging}")

    response = read_branches(paging, 'root')
    log_debug("response = #{response}")

    render(json: response)
    audit_action_fine(:list, 'root')
  rescue => e
    audit_action_failure(:list, e.message, 'root')
    handle_exception(e)
  end

  def update
    url_params = permit_url_params(URL_REQUIRED_PARAMS_IDFR)
    input = permit_body_params([], BRANCH_OPTIONAL_PARAMS)
    log_debug("url_params = #{url_params}, input = #{input}")

    authorize_update(path_identifier)

    branch_up = Branches::BranchUpPart.from_input(input)
    log_debug("branch_up = #{branch_up}")

    check_owner_exists_if_set(branch_up)

    updated_branch = update_branch(branch_up)
    log_debug("updated_branch = #{updated_branch}")

    render(json: updated_branch)
    audit_action_fine(:update, path_identifier, audit_payload)
  rescue => e
    audit_action_failure(:update, e.message, path_identifier, audit_payload)
    handle_exception(e)
  end

  def delete
    url_params = permit_url_params(URL_REQUIRED_PARAMS_IDFR)
    log_debug("url_params = #{url_params}")

    authorize_branch_for_del(path_identifier)
    delete_branch(path_identifier)

    head(:no_content)
    audit_action_fine(:remove)
  rescue => e
    audit_action_failure(:remove, e.message)
    handle_exception(e)
  end

  private

  # create

  def permit_create_url_params
    permit_url_params(URL_REQUIRED_PARAMS)
  end

  def permit_create_body_params
    permit_body_params(%i[name branch], BRANCH_OPTIONAL_PARAMS)
  end

  def authorize_create_in_parent(branch)
    read_and_auth_branch(:create, branch.branch)
  end

  def check_branch_not_conflict(branch)
    @branch_service.check_branch_not_conflict(account, branch.identifier)
  end

  def check_owner_exists_if_set(branch)
    return unless branch.owner.set?

    @owner_service.check_owner_exists(account, branch.owner)
  end

  def create_branch(branch)
    @branch_service.check_parent_branch_exists(account, branch.branch)
    @branch_service.create_branch(account, branch)
  end

  # show

  def authorize_read(identifier)
    read_and_auth_branch(:read, identifier)
  end

  def get_branch(identifier)
    @branch_service.check_parent_branch_exists(account, identifier)
    @branch_service.get_branch(account, identifier)
  end

  # index

  def read_branches(paging, identifier)
    @branch_service.check_parent_branch_exists(account, identifier)
    @branch_service.read_branches(current_user.role_id, account, paging, identifier)
  end

  # update

  def authorize_update(identifier)
    read_and_auth_branch(:read, identifier)
    read_and_auth_branch(:update, identifier)
  end

  def update_branch(branch_up, identifier = path_identifier)
    @branch_service.check_parent_branch_exists(account, identifier)
    @branch_service.update_branch(account, branch_up, identifier)
  end

  # delete

  def authorize_branch_for_del(identifier)
    read_and_auth_branch(:update, identifier)
  end

  def delete_branch(identifier)
    @branch_service.check_parent_branch_exists(account, identifier)
    @branch_service.delete_branch(account, current_user, identifier)
  end

  # audit

  def audit_action_fine(action, identifier = path_identifier, body_json_str = nil)
    audit_success('branch', action, identifier, body_json_str)
  end

  def audit_action_failure(action, err_msg, identifier = path_identifier, body_json_str = nil)
    audit_failure('branch', action, identifier, err_msg, body_json_str)
  end

  def audit_action_create_failure(err_msg)
    bps = permit_create_body_params
    parent_identifier = bps[:branch] || ''
    name = bps[:name] || ''
    identifier = parent_identifier && name ? to_identifier(parent_identifier, name) : parent_identifier + name
    audit_action_failure(:create, err_msg, identifier, audit_payload)
  end
end

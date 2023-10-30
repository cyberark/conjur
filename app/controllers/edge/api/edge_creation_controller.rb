
require_relative '../../wrappers/policy_wrapper'

class EdgeCreationController < RestController
  include AccountValidator
  include BodyParser
  include ExtractEdgeResources
  include EdgeValidator
  include EdgeYamls
  include FindEdgePolicyResource
  include GroupMembershipValidator
  include PolicyWrapper
  include ParamsValidator

  def generate_install_token
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("edge/edge-creds"))
    allowed_params = %i[account edge_name]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    audit_params = { edge_name: options[:edge_name], user: current_user.role_id, client_ip: request.ip }
    begin
      validate_conjur_admin_group(options[:account])

      edge = Edge[name: options[:edge_name]] || (raise RecordNotFound.new(options[:edge_name], message: "Edge #{options[:edge_name]} not found"))
      installer_token = edge.get_installer_token(options[:account], request)

      edge_host_name = Role.username_from_roleid(edge.get_edge_host_name(options[:account]))

    rescue => e
      audit_params[:error_message] = e.message
      raise e
    ensure
      Audit.logger.log(Audit::Event::CredsGeneration.new(**audit_params))
    end
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("edge/edge-creds"))
    response.set_header("Content-Encoding", "base64")
    render(plain: Base64.strict_encode64(edge_host_name + ":" + installer_token))
  end

  #this endpoint loads a policy with the edge host values + adds the edge name to Edge table
  def create_edge
    logger.debug(LogMessages::Endpoints::EndpointRequested.new('create edge'))
    allowed_params = %i[account edge_name]
    url_params = params.permit(*allowed_params)
    validate_conjur_admin_group(url_params[:account])
    edge_name = url_params[:edge_name]
    validate_name(edge_name)
    params[:identifier] = "edge"

    begin
      validate_max_edge_allowed(url_params[:account])
      Edge.new_edge(name: edge_name)
      edge = Edge[name: edge_name]
      add_edge_host_policy(edge[:id])
    rescue => e
      @error_message = e.message
      raise e
    ensure
      created_audit(edge_name)
    end
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("create edge"))
    head :created
  end

  private

  def validate_max_edge_allowed(account)
    max_edges = extract_max_edge_value(account)
    table_size = Edge.count
    raise UnprocessableEntity, "Edge number exceeded max edge allowed" unless table_size < max_edges.to_i
  end

  def add_edge_host_policy(host_id)
    input = input_post_yaml(host_id)
    submit_policy(Loader::CreatePolicy, PolicyTemplates::CreateEdge.new(), input,resource)
  end

  def created_audit(edge_name = "not-found")
    audit_params = { edge_name: edge_name, user: current_user.role_id, client_ip: request.ip}
    audit_params[:error_message] = @error_message if @error_message
    Audit.logger.log(Audit::Event::EdgeCreation.new(
      **audit_params
    ))
  end

  def validate_name(name)
    validate_params({"edge_name" => name}, ->(k,v){
      !v.nil? && !v.empty? &&
      v.match?(/^[a-zA-Z0-9_]+$/) && string_length_validator(0, 60).call(k, v)
    })
  end

end
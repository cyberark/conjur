
require_relative '../controllers/wrappers/policy_wrapper'

class EdgeCreatorController < RestController
  include AccountValidator
  include BodyParser
  include EdgeValidator
  include ExtractEdgeResources
  include FindEdgePolicyResource
  include GroupMembershipValidator
  include PolicyWrapper

  #this endpoint loads a policy with the edge host values + adds the edge name to Edge table
  def create_edge
    logger.info(LogMessages::Endpoints::EndpointRequested.new('create edge'))
    allowed_params = %i[account edge_name]
    url_params = params.permit(*allowed_params)
    validate_conjur_admin_group(url_params[:account])
    validate_name(url_params[:edge_name])
    params[:identifier] = "edge"
    edge_name = params[:edge_name]

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
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("create edge"))
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

  def input_post_yaml(json_body)
    {
      "edge_identifier" => json_body
    }
  end

  def created_audit(edge_name = "not-found")
    audit_params = { edge_name: edge_name, user: current_user.role_id, client_ip: request.ip}
    audit_params[:error_message] = @error_message if @error_message
    Audit.logger.log(Audit::Event::EdgeCreation.new(
      **audit_params
    ))
  end

  def validate_name(name)
    if name.nil? || name.empty?
      raise ApplicationController::UnprocessableEntity, "edge_name param is missing in body, must not be blank."
    end
  end

end
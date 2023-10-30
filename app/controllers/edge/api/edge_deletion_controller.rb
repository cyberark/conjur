# frozen_string_literal: true

class EdgeDeletionController < RestController
  include AccountValidator
  include EdgeYamls
  include GroupMembershipValidator
  include PolicyWrapper
  include FindEdgePolicyResource

  EDGE_NOT_FOUND = "Edge not found"

  def delete_edge
    logger.info(LogMessages::Endpoints::EndpointRequested.new("DELETE edge/#{params[:account]}/#{params[:identifier]}"))
    validate_conjur_admin_group(params[:account])
    edge_record = get_edge_from_db(params[:identifier])
    unless edge_record
      raise Exceptions::RecordNotFound.new(params[:identifier], message: EDGE_NOT_FOUND)
    end
    delete_edge_host_policy(edge_record.id)
    edge_record.destroy
    head(204)
    deleted_audit(params[:identifier])
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("DELETE edge/#{params[:account]}/#{params[:identifier]}"))
  rescue Exceptions::RecordNotFound => e
    @error_message = e.message
    deleted_audit(params[:identifier])
    raise Exceptions::RecordNotFound.new(params[:identifier], message: EDGE_NOT_FOUND)
  rescue => e
    @error_message = e.message
    deleted_audit(params[:identifier])
    logger.error(LogMessages::Conjur::GeneralError.new(e.message))
    raise e
  end

  private

  def get_edge_from_db(edge_name)
    Edge.where(name: edge_name).first
  end
  def delete_edge_host_policy(host_id)
    input = input_post_yaml(host_id)
    submit_policy(Loader::ModifyPolicy, PolicyTemplates::DeleteEdge.new(), input, resource, true)
  end

  def deleted_audit(edge_name = "not-found")
    audit_params = { edge_name: edge_name, user: current_user.role_id, client_ip: request.ip}
    audit_params[:error_message] = @error_message if @error_message
    Audit.logger.log(Audit::Event::EdgeDeletion.new(
      **audit_params
    ))
  end
end

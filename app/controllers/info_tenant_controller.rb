# frozen_string_literal: true

class InfoTenantController < V2RestController
  def get
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("Get info about the tenant"))
    begin
      synchronizer_policy = "#{account}:policy:synchronizer"
      synchronizerPolicyResource = Resource.find(resource_id: synchronizer_policy)

      is_pam_self_hosted = !synchronizerPolicyResource.nil?
      logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("Get info endpoint"))
      response.set_header("Content-Type", "application/json")
      render(json: {is_pam_self_hosted: is_pam_self_hosted }, status: :ok)

    rescue => e
      logger.warn(LogMessages::Conjur::GeneralError.new(e.message))
      raise e
    end
  end

end

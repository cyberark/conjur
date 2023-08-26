require_relative '../../../domain/edge_logic/replication/authenticators_replicator'

class EdgeAuthenticatorsController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator
  include AuthenticatorsReplicator
  def all_authenticators
    logger.info(LogMessages::Endpoints::EndpointRequested.new("all-authenticators"))
    allowed_params = %i[account kind limit offset count]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    begin
      verify_edge_host(options)
    rescue ApplicationController::Forbidden
      raise
    end
    account = options[:account]

    allowed_kind = ['authn-jwt']
    kinds = options[:kind].split(',')
    unless kinds.all? { |value| allowed_kind.include?(value) }
      raise InternalServerError , "authenticator kind parameter is not valid"
    end

    accepts_base64 = String(request.headers['Accept-Encoding']).casecmp?('base64')
    unless accepts_base64
      raise InternalServerError , "the header request must contain base64 accept-encoding"
    end

    response.set_header("Content-Encoding", "base64")

    begin
      return_json = get_authenticators_data(kinds)
    rescue => e
      raise e
    end

    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("all-authenticators"))
    render(json: return_json)

  end
end

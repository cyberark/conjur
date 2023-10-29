class EdgeSlosiloKeysController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator

  def slosilo_keys
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("slosilo_keys"))
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    begin
      verify_edge_host(options)
    rescue ApplicationController::Forbidden
      raise
    end
    account = options[:account]

    key = Account.token_key(account, "host")
    if key.nil?
      raise RecordNotFound, "No Slosilo key in DB"
    end
    return_json = {}
    key_object = [get_key_object(key)]
    return_json[:slosiloKeys] = key_object

    prev_key = Account.token_key(account, "host", "previous")
    prev_key_obj = prev_key.nil? ? [] : [get_key_object(prev_key)]
    return_json[:previousSlosiloKeys] = prev_key_obj

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("slosilo_keys"))
    render(json: return_json)
  end

  private

  def get_key_object(key)
    private_key = key.to_der.unpack("H*")[0]
    fingerprint = key.fingerprint
    variable_to_return = {}
    variable_to_return[:privateKey] = private_key
    variable_to_return[:fingerprint] = fingerprint
    variable_to_return
  end

end
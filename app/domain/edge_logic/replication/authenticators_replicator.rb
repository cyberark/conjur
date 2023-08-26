# frozen_string_literal: true
require_relative '../../../models/authenticators'
module AuthenticatorsReplicator
  def get_authenticators_data(kinds)
    return_json = {}
    kinds.each { |str| return_json[str] = authn_jwt_handler }
    return_json
  end

  def authn_jwt_handler
    result = get_authenticators
    result
  end
  def jwt_properties_validation
    allowed_properties = ['jwks-uri' 'public-keys' 'ca-cert' 'token-app-property' 'identity-path' 'issuer' 'enforced-claims' 'claim-aliases' 'audience']
  end

end
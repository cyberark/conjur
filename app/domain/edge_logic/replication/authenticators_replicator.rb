# frozen_string_literal: true
module AuthenticatorsReplicator
  def get_authenticators_data(kinds)
    return_json = {}
    kinds.each { |str| return_json[str] = authn_jwt_handler }
    return_json
  end

  def authn_jwt_handler
    results = []
    authn_prefix = "webservice:conjur/authn-jwt/"
    authenticators = Resource.where(:resource_id.like("%#{authn_prefix}%"))
    authenticators.each do |authenticator|
      authenticatorToReturn = {}
      authenticatorToReturn[:id] = authenticator[:resource_id]
      authenticatorToReturn[:permissions] = []
      Permission.where(:resource_id.like("#{authenticatorToReturn[:id]}")).each do |row|
        permission = {}
        permission[:privilege] = row[:privilege]
        permission[:role] = row[:role_id]
        authenticatorToReturn[:permissions].append(permission)
      end
      enable_entry = AuthenticatorConfig.first(resource_id: authenticatorToReturn[:id])
      authenticatorToReturn[:enabled] = enable_entry ? enable_entry.enable : false
      jwt_properties_validation(authenticatorToReturn)
      results << authenticatorToReturn
    end
    results
  end
  def jwt_properties_validation(record)
    allowed_properties = ['jwks-uri' 'public-keys' 'ca-cert' 'token-app-property' 'identity-path' 'issuer' 'enforced-claims' 'claim-aliases' 'audience']
    unless record[:id].is_a?(String)
      raise InternalServerError , "the id record is not a string type"
    end
  end

end
# frozen_string_literal: true
module AuthenticatorsManager
  def get_authenticators_data(kinds)
    return_json = {}
    kinds.each do |kind|
      if kind == "authn-jwt"
        return_json[kind] = authn_jwt_handler
      end
    end
    return_json
  end

  def authn_jwt_handler
    results = []
    begin
      authenticators = Authenticator.jwt
      authenticators.each do |authenticator|
        authenticatorToReturn = {}
        authenticatorToReturn[:id] = authenticator[:resource_id]
        if verify_path(authenticator[:resource_id])
          next
        end
        authenticatorToReturn[:enabled] = authenticator[:enabled]
        authenticatorToReturn[:permissions] = nil
        if JSON.parse(authenticator[:permissions]).first["role_id"]!=nil
          authenticatorToReturn[:permissions] = []
          JSON.parse(authenticator[:permissions]).each do |row|
            permissionToReturn = {}
            permissionToReturn[:role] = row["role_id"]
            permissionToReturn[:privilege] = row["privilege"]
            authenticatorToReturn[:permissions] << permissionToReturn
          end
          authenticatorToReturn[:permissions].sort_by { |item| item[:privilege] }
        end
        authenticatorToReturn[:jwksUri] = nil
        authenticatorToReturn[:publicKeys] = nil
        authenticatorToReturn[:caCert] = nil
        authenticatorToReturn[:tokenAppProperty]  = nil
        authenticatorToReturn[:identityPath] = nil
        authenticatorToReturn[:issuer] = nil
        authenticatorToReturn[:enforcedClaims] = nil
        authenticatorToReturn[:claimAliases] = nil
        authenticatorToReturn[:audience] = nil
        results << authenticatorToReturn
        end
    rescue => e
        raise InternalServerError, e.message
    end
    results
  end

  private

  def verify_path(resource_id)
    # we want to verify the authenticator is only two levels under root/conjur in the policy tree
    # otherwise it is not a valid authenticator.
    resource_id.length - resource_id.delete('/').length>2
  end
end

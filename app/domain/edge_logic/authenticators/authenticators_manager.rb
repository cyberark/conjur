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
    unique_properties = %w[jwksUri publicKeys caCert tokenAppProperty identityPath issuer enforcedClaims claimAliases audience]
    unique_properties_name_in_policy = %w[jwks-uri public-keys ca-cert token-app-property identity-path issuer enforced-claims claim-aliases audience]
    property_map = unique_properties_name_in_policy.zip(unique_properties).to_h
    begin
      authenticators = Authenticator.jwt
      authenticators.each do |authenticator|
        authenticatorToReturn = {}
        authenticatorToReturn[:id] = authenticator[:resource_id]
        unless validate_authenticator_path(authenticator[:resource_id])
          next
        end
        # if the the enable is not configured the default value will be false
        authenticatorToReturn[:enabled] = authenticator[:enabled]
        # if there is no permissions for authenticator the default value will be nil
        authenticatorToReturn[:permissions] = nil
        if JSON.parse(authenticator[:permissions]).first["role_id"]!=nil
          authenticatorToReturn[:permissions] = []
          JSON.parse(authenticator[:permissions]).each do |row|
            permissionToReturn = {}
            permissionToReturn[:role] = row["role_id"]
            permissionToReturn[:privilege] = row["privilege"]
            authenticatorToReturn[:permissions] << permissionToReturn
          end
          authenticatorToReturn[:permissions] = authenticatorToReturn[:permissions].sort_by { |item| item[:privilege] }
        end
        # set all the 8 unique properties to be nil by default
        nil_properties_hash = unique_properties.map { |property| [property, nil] }.to_h
        authenticatorToReturn.merge!(nil_properties_hash)
        # if the property_id is in the claims list is means the claims configured
        # if it configured in the policy the property value should be empty string
        # if the property set to a new value, it should be the actual value
        JSON.parse(authenticator[:claims]).each do |claim|
          full_id = claim["property_id"]
          key = full_id.split("/").last
          key_mapping = property_map[key]
          property_value = Authenticator.get_property(full_id)
          if key_mapping == "enforcedClaims"
            authenticatorToReturn[key_mapping] = build_enforced_claims(property_value)
          elsif key_mapping == "claimAliases"
            authenticatorToReturn[key_mapping] = build_claim_aliases(property_value)
          else
            authenticatorToReturn[key_mapping] = Base64.strict_encode64(property_value)
          end
        end
        results << authenticatorToReturn
      end
    rescue => e
        raise InternalServerError, e.message
    end
    # the authenticators are sorted by resource_id DESC
    results
  end

  private
  def validate_authenticator_path(resource_id)
    # Valid authenticator is only two levels under conjur policy in the policy tree
    # otherwise it is not a valid authenticator.
    # valid : conjur/authn-jwt/myVendor
    # not valid : conjur/authn-jwt/myVendor/status
    resource_id.count("/") == 2
  end

  def build_enforced_claims(value)
    # enforced-claims should be a array of strings seperated by comma
    if value == ""
      # if the value of enforced-claims is empty string it means it declared on the policy but never set a value.
      # in such a case, by design, we need to return empty string.
      value
    else
      result = value.split(',')
      result = result.map { |item| Base64.strict_encode64(item) }
      result
    end
  end

  def build_claim_aliases(value)
    # claim aliases should be a array of objects with "annotationName" : "claimName" structure
    if value == ""
      # if the value of claim aliases is empty string it means it declared on the policy but never set a value.
      # in such a case, by design, we need to return empty string.
      value
    else
      begin
        result = value.split(',').map do |pair|
          annotation, claim = pair.split(':')
          {
            "annotationName" => Base64.strict_encode64(annotation),
            "claimName" => Base64.strict_encode64(claim)
          }
        end
      rescue => e
        raise InternalServerError, e.message
      end
      result
    end
  end

end

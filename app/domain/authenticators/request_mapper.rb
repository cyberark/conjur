module Authenticators
  class RequestMapper 
    def initialize(validator: Authenticators::Validator.new)
      @validator = validator
      @success = Responses::Success
      @failure = Responses::Failure
    end

    def call(request_body, account)
      # TODO: Redo all validations as active record validations on the model
      @validator.call(request_body, account)

      @success.new({
        type: long_type(request_body[:type]),
        service_id: request_body[:name],
        owner_id: format_owner(request_body[:owner], account),
        enabled: request_body[:enabled],
        variables: format_variables(request_body[:data]),
        account: account,
        annotations: request_body[:annotations]
      })
    end

    private

    def format_owner(owner, account)
      "#{account}:#{owner[:kind]}:#{owner[:id]}" unless owner.nil?
    end

    def format_variables(variables)
      return nil unless variables

      if variables.key?(:public_keys)
        variables[:public_keys] = variables[:public_keys].to_json 
      end
      
      return variables unless variables.key?(:identity)

      identity = variables[:identity]
      identity.each do |k, v|
        identity[k] = formate_identity_values(k, v)
      end

      # Flatten the identity hash into the main variables hash and remove the identity key
      variables.merge!(identity).delete(:identity)

      variables
    end

    # When creating authenticator, we need to process certain fields like claim_aliases and enforced_claims
    # The claim_aliases field is received as a hash, and we need to convert it to a string format "key1:value1,key2:value2"
    # The enforced_claims field is received as an array, and we need to convert it to a string format "value1,value2"
    def formate_identity_values(key, value)
      case key
      when :claim_aliases
        value.to_h.map { |k, v| "#{k}:#{v}" }.join(",")
      when :enforced_claims
        value.join(",")
      else
        value
      end
    end

    def long_type(type)
      return nil unless type
      
      return "authn-iam" if type == "aws"

      "authn-#{type}"
    end
  end
end

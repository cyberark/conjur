# frozen_string_literal: true

module AuthenticatorsV2
  class AuthenticatorBaseType
    attr_accessor :type, :branch, :enabled, :owner, :name,
                  :annotations, :variables, :account

    def initialize(authenticator_dict)
      @account = authenticator_dict[:account]
      @type = authenticator_dict[:type]
      @service_id = authenticator_dict[:service_id]
      @name = authenticator_dict[:service_id]
      @enabled = authenticator_dict[:enabled]
      @owner = authenticator_dict[:owner_id]
      @annotations = authenticator_dict[:annotations]
      @variables = authenticator_dict[:variables]
    end

    def to_h
      res = {
        type: format_type(type),
        branch: "conjur/#{@type}",
        name: authenticator_name,
        enabled: @enabled,
        owner: parse_owner(@owner)
      }
      res[:data] = add_data_params(@variables) if respond_to?(:add_data_params)
      res[:annotations] = JSON.parse(@annotations) if @annotations.present?

      res
    end
  
    def format_type(authn_type)
      return "aws" if authn_type == "authn-iam"
      
      authn_type.split("-").last
    end

    def authenticator_name
      @service_id
    end
    
    private

    # Extracts a parameter from `authenticator_params` if it exists and
    # ensures it is UTF-8 encoded if it is a string
    #
    # @param [Hash] authenticator_params - Hash containing all authentication parameters.
    # @param [Symbol] key - The key to extract.
    # @return [String, Hash, nil] - Extracted value, processed if applicable, or `nil` if key is missing.
    def retrieve_authenticator_variable(authenticator_params, key)
      key_suffix = key.to_s.gsub('_', '-')  # Convert key to expected format
      matched_key = authenticator_params.keys.find { |param_key| param_key.end_with?(key.to_s) || param_key.end_with?(key_suffix) }
      return unless matched_key

      value = authenticator_params[matched_key].dup

      # Convert to UTF-8 only if it's a String
      # If it is string it means we get the params from db and we need to process them
      if value.is_a?(String)
        value.force_encoding('UTF-8')
      end

      value
    end

    # Parses owner string into a structured hash
    # Expected format: "#{account}:policy:conjur/authn-jwt"
    # Example:
    #   parse_owner("rspec:policy:conjur/authn-jwt")
    #   => { id: "conjur/authn-jwt", kind: "policy" }
    def parse_owner(owner_id)
      parts = owner_id.split(':', 3)
      {
        id: parts[2],
        kind: parts[1]
      }
    end
  end
end

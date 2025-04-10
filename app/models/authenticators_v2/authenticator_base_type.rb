# frozen_string_literal: true

module AuthenticatorsV2
  class AuthenticatorBaseType
    attr_accessor :type, :name, :branch, :enabled, :owner,
                  :annotations, :authenticator_variables

    def initialize(authenticator_dict)
      @type = authenticator_dict[:type]
      @name = authenticator_dict[:name]
      @branch = authenticator_dict[:branch]
      @enabled = authenticator_dict[:enabled]
      @owner = authenticator_dict[:owner]
      @annotations = authenticator_dict[:annotations]
      @authenticator_variables = authenticator_dict[:variables]
    end

    def as_json
      json_response = { type: type }

      json_response[:branch] = branch
      json_response[:name] = authenticator_name
      json_response[:enabled] = enabled

      json_response[:owner] = parse_owner(owner)

      json_response[:data] = add_data_params(authenticator_variables) if respond_to?(:add_data_params)

      json_response[:annotations] = annotations unless annotations.nil? || annotations.empty?

      json_response
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

    def authenticator_name
      name
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

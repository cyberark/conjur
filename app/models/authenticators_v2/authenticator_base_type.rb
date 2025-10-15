# frozen_string_literal: true

module AuthenticatorsV2
  class AuthenticatorBaseType
    attr_accessor :type, :name, :annotations, :variables, :account, :service_id

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
      {
        type: format_type(type),
        branch: branch,
        name: authenticator_name,
        enabled: enabled,
        owner: parse_owner(owner),
        data: data, 
        annotations: @annotations.present? ? annotations : nil
      }.compact
    end

    def format_type(authn_type)
      return "aws" if authn_type == "authn-iam"
      
      authn_type.split("-").last
    end

    def authenticator_name
      @service_id
    end

    def provider_details
      details = @variables
      details[:service_id] = @service_id
      details[:account] = @account

      details
    end

    def identifier
      [@type, @service_id].compact.join('/')
    end

    def resource_id
      [
        @account,
        'webservice',
        [
          'conjur',
          @type,
          @service_id
        ].compact.join('/')
      ].join(':')
    end
    
    def token_ttl
      nil
    end

    def variable_prefix
      "#{@account}:variable:conjur/#{identifier}"
    end

    def enabled
      return @enabled unless @enabled.nil?

      true
    end

    def id
      "conjur/#{type}/#{@service_id}"
    end

    def branch
      "conjur/#{type}"
    end

    def owner
      return @owner unless @owner.nil?

      "#{account}:policy:#{branch}"
    end

    private

    def data 
      nil
    end

    def filter_variables(fields)
      @variables.select { |k, _| fields.include?(k) }.transform_values { |v| format_field(v) }
    end

    def format_field(value)
      return nil if value.nil?
      
      value = value.dup.force_encoding('UTF-8') if value.is_a?(String)

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

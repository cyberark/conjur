module Authenticators
  class Validator 
    def call(params, account)
      validate_basic_structure(params)
      validate_owner(params)
      validate_data(params)
      validate_annotations(params[:annotations] || {})
      validate_gcp_name(params, account) if params[:type] == "gcp"
    end

    private

    # Validate essential fields: name, type and enabled
    def validate_basic_structure(params)
      basic_fields = {
        type: {
          validators: [] # validated against hash above
        },
        name: {
          field_info: { type: String, value: params[:name] },
          validators: [method(:validate_field_required), method(:validate_field_type), method(:validate_id)]
        },
        enabled: {
          field_info: { type: [TrueClass, FalseClass], value: params[:enabled] },
          validators: [method(:validate_field_type)]
        },
        owner: {
          field_info: { type: Hash, value: params[:owner] },
          validators: [method(:validate_field_type)] # validated further later
        },
        data: {
          field_info: { type: Hash, value: params[:data] },
          validators: [method(:validate_field_type)] # validated further later
        },
        annotations: {
          field_info: { type: Hash, value: params[:annotations] },
          validators: [method(:validate_field_type)] # validated further later
        }
      }

      validate_no_extra_json_params(params, basic_fields)
      validate_data_fields(basic_fields)
    end

    # Validate the name field for GCP authenticator - must be the default name defined as "default"
    # @param [String] name of the authenticator
    # @raise [Exceptions::RecordNotFound] if the name is not the default name
    # @return [void]
    def validate_gcp_name(params, account)
      return if params[:name].eql?(AuthenticatorsV2::GcpAuthenticatorType::GCP_DEFAULT_NAME)

      raise Exceptions::RecordNotFound, "#{account}:webservice:conjur/gcp/#{params[:name]}"
    end

    # Validate the owner field, ensuring both ID and kind are correctly formatted
    def validate_owner(params)
      owner = params[:owner]
      return if owner.nil?

      owner_fields = {
        id: {
          field_info: { type: String, value: owner[:id] },
          validators: [method(:validate_field_required), method(:validate_field_type), method(:validate_resource_id)]
        },
        kind: {
          field_info: { type: String, value: owner[:kind] },
          validators: [method(:validate_field_required), method(:validate_field_type), ->(_, field_info) { validate_resource_kind(field_info[:value], owner[:id], %w[user host group]) }]
        }
      }
      validate_no_extra_json_params(owner, owner_fields)
      validate_data_fields(owner_fields)
    end

    def validate_resource_kind(resource_kind, resource_id, allowed_kind)
      return if allowed_kind.include?(resource_kind)

      raise Errors::Conjur::ParameterValueInvalid.new(
        "Resource '#{resource_id}' kind",
        "Allowed values are #{allowed_kind}"
      )
    end

    def validate_resource_id(param_name, data)
      validate_string(
        param_name,
        data[:value],
        %r{\A[a-zA-Z0-9@._/-]+\z},
        500,
        1,
        "Valid characters: letters, numbers, and these special characters " \
          "are allowed: @ . _ / -. Other characters are not allowed."
      )
    end

    # Additional data validation
    # @raise for data any of [empty, String, nil for type= jwt or azure, not-nil for type= aws or gcp]
    def validate_data(params)
      data = params[:data]
      # Raise error for aws and azure authenticators if the request body contains a 'data' object
      type = params[:type]
      if %w[aws gcp].include?(type)
        if data
          raise(
            ApplicationController::UnprocessableEntity,
            "The 'data' object cannot be specified for #{type} authenticators."
          )
        end

        return
      elsif data.nil? || data.empty?
        return if type == "ldap" # LDAP is allowed to have no data block for certain configs

        raise(
          ApplicationController::UnprocessableEntity,
          "The 'data' object must be specified for #{type} authenticators and it must be a non-empty JSON object."
        )
      end

      data_fields = \
        case params[:type]
        when "jwt"
          jwt_data_validators(params[:data])
        when "k8s"
          k8s_data_validators(params[:data])
        when "azure"
          azure_data_validators(params[:data])
        when "oidc"
          oidc_data_validators(params[:data])
        when "ldap"
          ldap_data_validators(params[:data])
        else
          {}
        end

      validate_data_fields(data_fields)
      validate_identity_data(data)
      validate_data_rules(params[:type], params[:data])
      validate_no_extra_json_params(data, data_fields)
    end

    def ldap_data_validators(data)
      # LDAP is allowed to exclude the data block for legacy configuration
      return {} if data.nil?

      validate_ldap_vars = lambda do |_, _|
        return unless data[:bind_password].nil? && !data[:tls_ca_cert].nil?

        # Using tls-ca-cert implies we are using the variable/annotation config for this authenticator
        # which implies we require the bind-password be set
        raise(
          Errors::Conjur::ParameterMissing,
          "The 'bind_password' field must be specified when the 'tls_ca_cert' field is provided."
        )
      end

      {
        bind_password: {
          field_info: { type: String, value: data[:bind_password] },
          validators: [method(:validate_field_type)]
        },
        tls_ca_cert: {
          field_info: { type: String, value: data[:tls_ca_cert] },
          validators: [method(:validate_field_type), validate_ldap_vars]
        }
      }
    end

    def jwt_data_validators(data)
      {
        ca_cert: {
          field_info: { type: String, value: data[:ca_cert] },
          validators: [method(:validate_field_type)]
        },
        audience: {
          field_info: { type: String, value: data[:audience] },
          validators: [method(:validate_field_type), ->(_, field_info) { validate_not_allowed_chars_and_length("audience", field_info, 1000) }]
        },
        jwks_uri: {
          field_info: { type: String, value: data[:jwks_uri] },
          validators: [method(:validate_field_type), ->(_, field_info) { validate_not_allowed_chars_and_length("jwks_uri", field_info, 255) }]
        },
        public_keys: {
          field_info: { type: Hash, value: data[:public_keys] },
          validators: [method(:validate_field_type), ->(_, field_info) { validate_json_max_length("public_keys", field_info, 10000) }]
        },
        issuer: {
          field_info: { type: String, value: data[:issuer] },
          validators: [method(:validate_field_type), ->(_, field_info) { validate_not_allowed_chars_and_length("issuer", field_info, 255) }]
        },
        identity: {
          field_info: { type: Hash, value: data[:identity] },
          validators: [method(:validate_field_type)] #  validated later
        }
      }
    end

    def k8s_data_validators(data)
      {
        "kubernetes/ca_cert": {
          field_info: { type: String, value: data[:"kubernetes/ca_cert"] },
          validators: [method(:validate_field_type)]
        },
        "kubernetes/service_account_token": {
          field_info: { type: String, value: data[:"kubernetes/service_account_token"] },
          validators: [method(:validate_field_type)]
        },
        "kubernetes/api_url": {
          field_info: { type: String, value: data[:"kubernetes/api_url"] },
          validators: [method(:validate_field_type)]
        },
        "ca/key": {
          field_info: { type: String, value: data[:"ca/key"] },
          validators: [method(:validate_field_type), method(:validate_field_required)]
        },
        "ca/cert": {
          field_info: { type: String, value: data[:"ca/cert"] },
          validators: [method(:validate_field_type), method(:validate_field_required)]
        }
      }
    end

    def azure_data_validators(data)
      {
        provider_uri: {
          field_info: { type: String, value: data[:provider_uri] },
          validators: [method(:validate_field_type), method(:validate_field_required), ->(_, field_info) { validate_not_allowed_chars_and_length("provider_uri", field_info, 255) }]
        }
      }
    end

    def oidc_data_validators(data)
      {
        provider_uri: {
          field_info: { type: String, value: data[:provider_uri] },
          validators: [method(:validate_field_type), method(:validate_field_required), ->(_, field_info) { validate_not_allowed_chars_and_length("provider_uri", field_info, 255) }]
        },
        id_token_user_property: {
          field_info: { type: String, value: data[:id_token_user_property] },
          validators: [method(:validate_field_type), ->(_, field_info) { validate_not_allowed_chars_and_length("id_token_user_property", field_info, 255) }]
        },
        client_id: {
          field_info: { type: String, value: data[:client_id] },
          validators: [method(:validate_field_type)]
        },
        client_secret: {
          field_info: { type: String, value: data[:client_secret] },
          validators: [method(:validate_field_type)]
        },
        redirect_uri: {
          field_info: { type: String, value: data[:redirect_uri] },
          validators: [method(:validate_field_type)]
        },
        claim_mapping: {
          field_info: { type: String, value: data[:claim_mapping] },
          validators: [method(:validate_field_type)]
        },
        name: {
          field_info: { type: String, value: data[:name] },
          validators: [method(:validate_field_type)]
        },
        ca_cert: {
          field_info: { type: String, value: data[:ca_cert] },
          validators: [method(:validate_field_type)]
        },
        token_ttl: {
          field_info: { type: String, value: data[:token_ttl] },
          validators: [method(:validate_field_type)]
        },
        provider_scope: {
          field_info: { type: String, value: data[:provider_scope] },
          validators: [method(:validate_field_type)]
        }
      }
    end

    def validate_identity_data(params)
      identity = params[:identity]
      return if identity.nil?

      identity_data_fields = {
        claim_aliases: {
          field_info: { type: Hash, value: identity[:claim_aliases] },
          validators: [method(:validate_field_type), method(:validate_claim_aliases)]
        },
        enforced_claims: {
          field_info: { type: Array, value: identity[:enforced_claims] },
          validators: [method(:validate_field_type), method(:validate_enforced_claims)]
        },
        identity_path: {
          field_info: { type: String, value: identity[:identity_path] },
          validators: [method(:validate_field_type)]
        },
        token_app_property: {
          field_info: { type: String, value: identity[:token_app_property] },
          validators: [method(:validate_field_type), ->(_, field_info) { validate_not_allowed_chars_and_length("token_app_property", field_info, 1000) }]
        }
      }

      validate_data_fields(identity_data_fields)
      validate_no_extra_json_params(identity, identity_data_fields)
    end

    # Validate rules for the parameters
    def validate_data_rules(type, data)
      case type
      when "jwt"
        validate_jwt_data_rules(data)
      when "azure"
        validate_azure_data_rules(data)
      when "oidc"
        validate_oidc_data_rules(data)
      end
    end

    def validate_jwt_data_rules(data)
      # Ensure either `jwks_uri` or `public_keys` is present
      if data[:jwks_uri].nil? && data[:public_keys].nil?
        raise(
          ApplicationController::UnprocessableEntity,
          "In the 'data' object, either a 'jwks_uri' or 'public_keys' field must be specified."
        )
      end

      # Ensure `jwks_uri` and `public_keys` are not present together
      if data[:jwks_uri] && data[:public_keys]
        raise(
          ApplicationController::UnprocessableEntity,
          "In the 'data' object, you cannot specify jwks_uri and public_keys fields."
        )
      end

      # If `public_keys` is provided, `issuer` must also be provided
      if data[:public_keys] && data[:issuer].nil?
        raise(
          ApplicationController::UnprocessableEntity,
          "In the 'data' object, when the 'public_keys' field is specified, the 'issuer' field must also be specified."
        )
      end

      # If `identity_path` is provided, `token_app_property` must also be provided
      return unless data.dig(:identity, :identity_path) && data.dig(:identity, :token_app_property).nil?

      raise(
        ApplicationController::UnprocessableEntity,
        "In the identity object, when the 'identity_path' field is specified, the 'token_app_property' field must also be specified."
      )
    end

    def validate_azure_data_rules(data)
      # `provider_uri` must be provided
      return unless data[:provider_uri].nil?

      raise(
        ApplicationController::UnprocessableEntity,
        "In the 'data' object, the 'provider_uri' field must be specified."
      )
    end

    def validate_oidc_data_rules(data)
      # These variables are required for standard OIDC auth setup
      standard = %i[id_token_user_property]
      # These variables are required for mfa OIDC auth setup
      mfa = %i[client_id client_secret redirect_uri claim_mapping]
      exclusivity_message = "The data object must contain either " \
        "#{standard.map(&:to_s)} or #{mfa.map(&:to_s)} keys."

      # Select chooses variables not in the 'data' dict so by checking if the result is empty
      # determines if any vars in standard are not included as keys in data
      all_standard_variables_included = standard.reject{ |v| data.include?(v) }.empty?
      all_mfa_variables_included = mfa.reject{ |v| data.include?(v) }.empty?

      # Determines if some (but not necessarily all) of the vars are in data
      standard_variables_included = !standard.select{ |v| data.include?(v) }.empty?
      mfa_variables_included = !mfa.select{ |v| data.include?(v) }.empty?

      if !all_standard_variables_included && !all_mfa_variables_included
        raise ApplicationController::UnprocessableEntity, exclusivity_message
      end

      if all_standard_variables_included && all_mfa_variables_included
        raise ApplicationController::UnprocessableEntity, exclusivity_message
      end

      # This is the case where we have a partial config for one/both sets of vars
      return unless standard_variables_included && mfa_variables_included

      raise ApplicationController::UnprocessableEntity, exclusivity_message
    end

    def validate_field_required(param_name, data)
      # The field exists in data
      # If data[:value] is missing (i.e., nil) or it's an empty string (""), then raise a ParameterMissing error.
      return unless data[:value].nil? || (data[:value].is_a?(String) && data[:value].empty?)

      raise Errors::Conjur::ParameterMissing, param_name
    end

    def validate_field_type(param_name, data)
      return if data[:value].nil?

      expected_types = Array(data[:type]) # Ensure it's an array
      return if expected_types.any? { |type| data[:value].is_a?(type) }

      json_type_names = expected_types.map { |type| ruby_class_to_json_type(type) }.uniq
      raise Errors::Conjur::ParameterTypeInvalid.new(param_name, json_type_names.map(&:to_s).join(', '))
    end

    def ruby_class_to_json_type(klass)
      classes = {
        String => "string",
        Integer => "number",
        Float => "number",
        Numeric => "number",
        TrueClass => "true",
        FalseClass => "false",
        Hash => "object",
        Array => "array"
      }

      classes[klass] || klass.to_s.downcase
    end

    def validate_data_fields(fields_validations)
      fields_validations.each do |field_name, field_validation|
        field_validation[:validators].each do |validator|
          validator.call(field_name, field_validation[:field_info])
        end
      end
    end

    def validate_no_extra_json_params(given, expected)
      extra_keys = given.keys.map(&:to_s) - expected.keys.map(&:to_s)
      return unless extra_keys.any?

      raise(
        ApplicationController::UnprocessableEntity,
        "The following parameters were not expected: #{extra_keys.join(', ')}"
      )
    end

    def validate_id(param_name, data)
      validate_string(param_name, data[:value], /\A[a-zA-Z0-9._:-]+\z/, 60, 1,
                      "Valid characters: letters, numbers, and these special characters are allowed: . _ : -. Other characters are not allowed.")
    end

    def validate_json_max_length(param_name, data, max_length)
      json_string = data.to_json
      return unless json_string.length > max_length

      raise(
        ApplicationController::UnprocessableEntity,
        "'#{param_name}' parameter length exceeded. Limit the length to #{max_length} characters"
      )
    end
    
    def validate_string(param_name, data, regex_pattern, max_size, min_size, error_message = "")
      return if data.nil?

      if data.length < min_size
        raise(
          ApplicationController::UnprocessableEntity,
          "'#{param_name}' parameter length is less than #{min_size} characters"
        )
      end

      if data.length > max_size
        raise(
          ApplicationController::UnprocessableEntity,
          "'#{param_name}' parameter length exceeded. Limit the length to #{max_size} characters"
        )
      end

      return if data.match?(regex_pattern)

      raise(
        ApplicationController::UnprocessableEntity,
        "Invalid '#{param_name}' parameter. #{error_message}"
      )
    end

    def validate_annotation_value(param_name, data)
      validate_string(param_name, data[:value], /^[^<>']+$/, 120, 1,
                      "All characters except less than (<), greater than (>), and single quote (') are allowed.")
    end

    def validate_path(param_name, data)
      validate_string(param_name, data[:value], %r{\A[a-zA-Z0-9_/-]+\z}, 500, 1,
                      "Valid characters: letters, numbers, and these special characters are allowed: _ / -. Other characters are not allowed.")
    end

    def validate_not_allowed_chars_and_length(param_name, data, max_length)
      # Ensure the string does not contain '<', '>', or spaces and does not exceed max_length
      # Dont validate if data value is nil because nil as value is valid
      return unless data[:value]

      validate_string(param_name, data[:value], /\A[^<> ]*\z/, max_length, 1,
                      "All characters except space ( ), less than (<), and greater than (>) are allowed.")
    end

    def validate_annotations(annotations)
      annotations.each_key do |annotation_key|
        data_fields = {
          "annotation name": {
            field_info: {
              type: String,
              value: annotation_key
            },
            validators: [method(:validate_path)]
          }
        }
        validate_data_fields(data_fields)
      end

      annotations.each_value do |annotation_value|
        data_fields = {
          "annotation value": {
            field_info: {
              type: String,
              value: annotation_value
            },
            validators: [
              method(:validate_field_required),
              method(:validate_field_type),
              method(:validate_annotation_value)
            ]
          }
        }
        validate_data_fields(data_fields)
      end
    end

    def validate_claim_aliases(param_name, data)
      reserved_claims = %w[iss exp nbf iat aud jti]
      return if data[:value].nil?
      
      unless data[:value].is_a?(Hash)
        raise(
          ApplicationController::UnprocessableEntity,
          "Invalid '#{param_name}' parameter. Must be a dictionary."
        )
      end

      data[:value].each do |target_alias, source_claim|
        target_alias = target_alias.to_s
        unless target_alias.match?(/\A[A-Za-z0-9_-]+\z/)
          raise(
            ApplicationController::UnprocessableEntity,
            "Invalid target alias '#{target_alias}' in '#{param_name}'. Must be an alphanumeric string with underscores or dashes."
          )
        end

        if reserved_claims.include?(target_alias)
          raise(
            ApplicationController::UnprocessableEntity,
            "Invalid target alias '#{target_alias}' in '#{param_name}'. Cannot use reserved claims: #{reserved_claims.join(', ')}."
          )
        end

        next if source_claim.is_a?(String) && source_claim.match?(%r{\A[A-Za-z0-9_-]+(?:/[A-Za-z0-9_-]+)*\z})

        raise(
          ApplicationController::UnprocessableEntity,
          "Invalid source claim '#{source_claim}' in '#{param_name}'. Must be a valid claim name or a nested path."
        )
      end
    end

    def validate_enforced_claims(param_name, data)
      return if data[:value].nil?
      return if data[:value].is_a?(Array) && data[:value].all? { |claim| claim.is_a?(String) }

      raise(
        ApplicationController::UnprocessableEntity,
        "Invalid '#{param_name}' parameter. Must be an array of strings."
      )
    end
  end
end

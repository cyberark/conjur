# frozen_string_literal: true

require 'base64'
require 'rest_client'
require 'json_schemer'
require 'factory/render_policy'

module Factory
  class CreateFromPolicyFactory
    def initialize(base64: Base64, renderer: Factory::RenderPolicy.new, http: RestClient, schema_validator: JSONSchemer)
      @base64 = base64
      @renderer = renderer
      @http = http
      @schema_validator = schema_validator
    end

    def validate!(schema:, params:)
      validator = @schema_validator.schema(schema)
      return if validator.valid?(params)

      error = validator.validate(params).first
      case error['type']
      when 'required'
        missing_attributes = error['details']['missing_keys'].map{|key| [ error['data_pointer'], key].reject{|item| item.empty?}.join('/') }.join("', '")
        raise "The following JSON attributes are missing: '#{missing_attributes}'"
      else
        raise "Generic JSON Schema validation error: type => '#{error['type']}', details => '#{error['type'].inspect}'"
      end
    end

    def call(factory_template:, request_body:, account:, authorization:)
      request_body = request_body.select{|_, v| v.present? }
      validate!(
        schema: factory_template['schema'],
        params: request_body
      )

      # Convert `dashed` keys to `underscored`.  This only occurs for top-level parameters.
      # Conjur variables should be use dashes rather than underscores.
      template_variables = request_body.transform_keys { |key| key.to_s.underscore }

      # Render the policy from the template and provided values
      policy_template = @base64.decode64(factory_template['policy'])

      # Push rendered policy to the desired policy branch
      policy_load_path = @renderer.render(template: factory_template['policy_namespace'], variables: template_variables)
      response = @http.post(
        "http://localhost:3000/policies/#{account}/policy/#{policy_load_path}",
        @renderer.render(template: policy_template, variables: template_variables),
        'Authorization' => authorization
      )

      if factory_template['schema']['properties'].key?('variables')
        variable_path = @renderer.render(template: "#{factory_template['policy_namespace']}/<%= id %>", variables: template_variables)
        factory_template['schema']['properties']['variables']['properties'].each_key do |factory_variable|
          variable_id = URI.encode_www_form_component("#{variable_path}/#{factory_variable}")

          @http.post(
            "http://localhost:3000/secrets/#{account}/variable/#{variable_id}",
            # All values must be sent to Conjur as strings
            template_variables['variables'][factory_variable].to_s,
            { 'Authorization' => authorization }
          )
        end
      end
      response
    end
  end
end

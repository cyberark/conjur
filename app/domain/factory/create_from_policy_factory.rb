# frozen_string_literal: true

require 'base64'
require 'rest_client'
require 'factory/render_policy'

module Factory
  class CreateFromPolicyFactory
    def initialize(base64: Base64, renderer: Factory::RenderPolicy.new, http: RestClient)
      @base64 = base64
      @renderer = renderer
      @http = http
    end

    def call(factory_template:, request_body:, account:, authorization:)
      # Strip any attributes not defined in the JSON schema
      json_params = factory_template['schema']['properties'].keys
      template_params = request_body.select { |k, _| json_params.include?(k) }

      # Verify the required JSON attributes are present in the JSON request body
      missing_params = factory_template['schema']['required'].difference(template_params.keys)
      unless (missing_params.empty?)
        raise "The following JSON parameters are missing from the request: '#{missing_params.join("','")}'"
      end

      # Render the policy from the template and provided values
      policy_template = @base64.decode64(factory_template['policy'])
      policy = @renderer.render(policy_template: policy_template, variables: template_params)

      # Push rendered policy to the desired policy branch
      @http.post("http://localhost:3000/policies/#{account}/policy/#{template_params['branch']}", policy, 'Authorization' => authorization)

    end
  end
end

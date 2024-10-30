# frozen_string_literal: true

module Factories
  class CreateFromPolicyFactory
    def initialize(base = Factories::Base.new)
      @base = base
      @policy_sub_loader = Loader::CreatePolicy

      # Defined here for visibility. We shouldn't need to mock these.
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def call(factory_template:, request_body:, account:, context:, request_method: 'POST', identifier: nil)
      @base.validate_and_transform_request(
        schema: factory_template.schema,
        params: request_body,
        identifier: identifier
      ).bind do |body_variables|
        format_template_variables(variables: body_variables, factory: factory_template).bind do |template_variables|
          # Push rendered policy to the desired policy branch
          @base.renderer.render(template: factory_template.policy_branch, variables: template_variables)
            .bind do |policy_load_path|
              policy_load_path = policy_load_path.split('/').reject(&:empty?).join('/')
              valid_variables = factory_template.schema['properties'].keys - ['variables']
              render_and_apply_policy(
                policy_load_path: policy_load_path,
                policy_template: factory_template.policy,
                variables: template_variables.select { |k, _| valid_variables.include?(k) },
                account: account,
                context: context,
                apply_policy_via: request_method
              ).bind do |result|
                return @success.new(result) unless factory_template.schema['properties'].key?('variables')

                # Set Policy Factory variables
                variables_path = ["{{ id }}"]
                # If the variables are headed for the "root" namespace, we don't want the namespace in the path
                variables_path.prepend(factory_template.policy_branch) unless policy_load_path == 'root'
                @base.renderer.render(template: variables_path.join('/'), variables: template_variables)
                  .bind do |variable_path|
                    @base.set_factory_variables(
                      context: context,
                      schema_variables: factory_template.schema['properties']['variables']['properties'],
                      factory_variables: template_variables['variables'],
                      variable_path: variable_path,
                      account: account
                    )
                  end
                  .bind do
                    # If variables were added successfully, return the result so that
                    # we send the policy load response back to the client.
                    @success.new(result)
                  end
              end
            end
        end
      end
    end

    private

    def format_template_variables(variables:, factory:)
      # Convert `dashed` keys to `underscored`.  This only occurs for top-level parameters.
      # Conjur variables should be use dashes rather than underscores.
      # Filter non-alpha-numeric, dash, forward slash, or underscore characters from inputs values (to prevent injection attacks).
      template_variables = variables
        .transform_keys { |key| key.to_s.underscore }
        .each_with_object({}) do |(key, value), rtn|
          # Only strip values that are rendered in the policy (not Conjur secret values)
          rtn[key] = if key == 'variables'
            value
          elsif value.is_a?(Hash)
            value.transform_values { |internal_value| @base.utilities.filter_input(internal_value.to_s) }
          else
            @base.utilities.filter_input(value.to_s)
          end
        end

      # Add empty `annotations` hash unless they've previously been set
      template_variables["annotations"] ||= {}

      template_variables['annotations'].merge!({ 'factory' => [
        factory.classification,
        factory.version,
        factory.name
      ].join('/') })

      @success.new(template_variables)
    end

    def render_and_apply_policy(policy_load_path:, policy_template:, variables:, account:, context:, apply_policy_via:)
      @base.renderer.render(
        template: policy_template,
        variables: variables
      ).bind do |rendered_policy|
        @base.logger.debug("Policy Factory is applying the following policy to '/policies/#{account}/policy/#{policy_load_path}'")
        @base.logger.debug("\n#{rendered_policy}")
        unless %w[POST PATCH].include?(apply_policy_via.to_s)
          return @failure.new(
            'Request method must be POST or PATCH',
            exception: Errors::Factories::InvalidAction.new(apply_policy_via, 'POST or PATCH'),
            status: :bad_request
          )
        end
        @base.policy_loader.call(
          target_policy_id: "#{account}:policy:#{policy_load_path}",
          context: context,
          policy: rendered_policy,
          loader: @policy_sub_loader,
          request_type: apply_policy_via
        ).bind do |result|
          return @success.new(result)
        end
      end
    end
  end
end

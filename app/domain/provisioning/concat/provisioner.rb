# frozen_string_literal: true

# The context provisioner provides secret values directly
# from the requests context (additional parameters provided
# alongside the policy document).
#
module Provisioning
  module Concat

    class Provisioner
      def provision(input)
        concat_with = input.resource.annotation('provision/concat/with') || ''
        
        input.resource.annotations
          .select { |a| a.name.start_with? 'provision/concat/' }
          .reject { |a| a.name == 'provision/concat/with' }
          .map do |a| 
            index, type = a.name.delete_prefix('provision/concat/').split('/')
            value = load_value(input.resource, type, a.value)

            {
              index: index.to_i,
              value: value
            }
          end
          .sort_by { |a| a[:index] }
          .map { |a| a[:value] }
          .join(concat_with)
      end

      private

      def load_value(resource, type, input_value)
        case type
        when 'literal'
          input_value
        when 'variable'
          variable_id = [resource.account, 'variable', input_value].join(":")
          Resource[variable_id].last_secret.value
        else
          raise "Invalid type given: #{type}"
        end
      end
    end
  end
end

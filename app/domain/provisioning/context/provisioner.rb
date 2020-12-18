# frozen_string_literal: true

# The context provisioner provides secret values directly
# from the requests context (additional parameters provided
# alongside the policy document).
#
module Provisioning
  module Context

    class Provisioner
      def provision(input)
        parameter = input.resource.annotation('provision/context/parameter')
        input.context[parameter.to_sym]
      end
    end
  end
end

# frozen_string_literal: true

require 'openssl'

# The context provisioner provides secret values directly
# from the requests context (additional parameters provided
# alongside the policy document).
#
module Provisioning
  module RSA

    class Provisioner
      def provision(input)
        length =  (input.resource.annotation('provision/rsa/length') || 2048).to_i
        key = OpenSSL::PKey::RSA.new length
        key.to_pem
      end
    end
  end
end

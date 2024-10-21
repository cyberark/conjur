# frozen_string_literal: true

module Testing
  module Factories
    class FactoryBuilder
      class << self
        def encode(str)
          Base64.strict_encode64(str)
        end

        def build(version:, policy:, policy_branch:, schema:)
          encode(
            {
              version: version,
              policy: encode(policy),
              policy_branch: policy_branch,
              schema: JSON.parse(schema)
            }.to_json.gsub(/\n/, '')
          )
        end
      end
    end
  end
end

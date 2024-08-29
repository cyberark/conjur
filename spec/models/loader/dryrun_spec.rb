# frozen_string_literal: true

require 'spec_helper'
require 'spec_helper_policy'

# Test outline:
# Verify shape of reponse to these dry-run policy submissions:
# - Validate successful policy
#   - create
#   - update
#   - replace

describe PoliciesController, type: :request do

  context '#put' do
    it 'policy load dry-run returns a complete, but empty, response' do
      validate_policy(
        action: :put,
        policy: <<~TEMPLATE
                   - !user alice
                TEMPLATE
      )
      expect(response.code).to match(/20\d/)
      expect(response.body).to eq(<<~EXPECTED.strip
{"status":"Valid YAML","created":{"items":[]},"updated":{"before":{"items":[]},"after":{"items":[]}},"deleted":{"items":[]}}
                                     EXPECTED
                                 )
    end
  end

  context '#patch' do
    it 'policy load dry-run returns a complete, but empty, response' do
      validate_policy(
        action: :patch,
        policy: <<~TEMPLATE
                   - !user charlie
                TEMPLATE
      )
      expect(response.code).to match(/20\d/)
      expect(response.body).to eq(<<~EXPECTED.strip
{"status":"Valid YAML","created":{"items":[]},"updated":{"before":{"items":[]},"after":{"items":[]}},"deleted":{"items":[]}}
                                     EXPECTED
                                 )
    end
  end

  context '#post' do
    it 'policy load dry-run returns a complete, but empty, response' do
      validate_policy(
        action: :post,
        policy: <<~TEMPLATE
                  - !user charlie
                TEMPLATE
      )
      expect(response.code).to match(/20\d/)
      expect(response.body).to eq(<<~EXPECTED.strip
{"status":"Valid YAML","created":{"items":[]},"updated":{"before":{"items":[]},"after":{"items":[]}},"deleted":{"items":[]}}
                                     EXPECTED
                                 )
    end
  end
end

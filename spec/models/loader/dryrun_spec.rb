# frozen_string_literal: true

require 'spec_helper'
require 'spec_helper_policy'

# Test outline:
# Verify shape of response to these dry-run policy submissions:
# - Invalid policy
# - Validate successful policy
#   - create
#   - update
#   - replace

# Not an empty file, but devoid of policy statements
basic_policy =
  <<~YAML
    #
  YAML

# Just a simple parse error, anything to cause policy invalid
bad_policy =
  <<~YAML
    - !!str, xxx
  YAML

bare_response =
  <<~EXPECTED.gsub(/\n/, '')
    {
    "status":"Valid YAML",
    "created":{
    "items":[]
    },
    "updated":{
    "before":{
    "items":[]
    },
    "after":{
    "items":[]
    }
    },
    "deleted":{
    "items":[]
    }
    }
  EXPECTED

def validation_status
  body = JSON.parse(response.body)
  body['status']
end

def validation_error_text
  body = JSON.parse(response.body)
  message = body['errors'][0]['message']
  message.match(/^(.*)\n*$/).to_s
end

describe PoliciesController, type: :request do

  context 'Invalid Policy ' do
    it 'returns only status and error, no dry-run fields' do
      validate_policy(
        action: :put,
        policy: bad_policy
      )
      expect(response.code).to eq("422")
      expect(validation_status).to match("Invalid YAML")
      expect(validation_error_text).to match(/did not find expected whitespace or line break/)
    end
  end

  context 'Valid Policy #put' do
    it 'returns status and a complete, but empty, dry-run response structure' do
      validate_policy(
        action: :put,
        policy: basic_policy
      )
      expect(response.code).to match(/20\d/)
      expect(response.body).to eq(bare_response)
      expect(validation_status).to match("Valid YAML")
    end
  end

  context 'Valid Policy #patch' do
    it 'returns status and a complete, but empty, dry-run response structure' do
      validate_policy(
        action: :patch,
        policy: basic_policy
      )
      expect(response.code).to match(/20\d/)
      expect(response.body).to eq(bare_response)
      expect(validation_status).to match("Valid YAML")
    end
  end

  context 'Valid Policy #post' do
    it 'returns status and a complete, but empty, dry-run response structure' do
      validate_policy(
        action: :post,
        policy: basic_policy
      )
      expect(response.code).to match(/20\d/)
      expect(response.body).to eq(bare_response)
      expect(validation_status).to match("Valid YAML")
    end
  end
end

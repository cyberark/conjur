# frozen_string_literal: true

require 'spec_helper'
require 'spec_helper_policy'

# This is intended as regression testing for the validation feature, not as a comprehensive test
# of policy cases.  Enough policy cases are included to exercise all the policy parsing error sources
# (YAML, resolving, conjur policy, and difficult cases).
# So that this won't become brittle the expectations follow these guidelines:
# - Include just enough error text to uniquely match
# - Use 'match' to expect the error_text string
# - Use explanation string expectation mainly to confirm that it is provided.  By matching as little as possible
#   of the advice string the text can be maintained or improved with some possibility of not breaking
#   its test.

def validation_status
  body = JSON.parse(response.body)
  body['status']
end

def validation_error_text
  body = JSON.parse(response.body)
  message = body['errors'][0]['message']
  message.match(/^(.*)\n*$/).to_s
end

def validation_explanation
  body = JSON.parse(response.body)
  msg = body['errors'][0]['message']
  adv = msg.match(/^[^\n]*\n{1,1}(.*)$/).to_s
  adv
end

describe PoliciesController, type: :request do
  describe '#put' do
    context 'with a policy that should validate successfully' do
      context 'such as user Alice' do
        it 'it returns Valid status and no error' do
          validate_policy(
            policy: <<~YAML
              - !user alice
            YAML
          )
          expect(response.code).to match(/20\d/)
          body = JSON.parse(response.body)
          expect(validation_status).to match("Valid YAML")
          expect(body['errors']).to match([])
        end
      end
    end

    context 'with a policy that should not validate successfully' do
      context 'such as YAML Test Suite U99R (PsychSyntaxError)' do
        it 'it returns Invalid status, the expected Error, and non-null advice' do
          validate_policy(
            policy: <<~YAML
              - !!str, xxx
            YAML
          )
          expect(response.code).to eq("422")
          expect(validation_status).to match("Invalid YAML")
          expect(validation_error_text).to match(/did not find expected whitespace or line break/)
          expect(validation_explanation).to match(/Only one node can be defined per line./)
        end
      end

      context 'such as unrecognized-type (ConjurPolicyParserInvalid)' do
        it 'it returns Invalid status, the expected Error, and non-null advice' do
          validate_policy(
            policy: <<~YAML
              - !foobar hello world
            YAML
          )
          expect(response.code).to eq("422")
          expect(validation_status).to match("Invalid YAML")
          expect(validation_error_text).to match(/Unrecognized data type/)
          expect(validation_explanation).to match(//)
        end
      end

      context 'such as invalid-cidr (ConjurPolicyParserInvalid)' do
        it 'it returns Invalid status, the expected Error, and non-null advice' do
          validate_policy(
            policy: <<~YAML
              - !host
                id: serviceA
                restricted_to: an_invalid_cidr_string
            YAML
          )
          expect(response.code).to eq("422")
          expect(validation_status).to match("Invalid YAML")
          expect(validation_error_text).to match(/Invalid IP address or CIDR range/)
          expect(validation_explanation).to match(/Make sure your address or range is in the correct format/)
        end
      end

      context 'such as samerecord (an error-prone parse case)' do
        it 'returns Valid status, expected Error, and advice' do
          validate_policy(
            policy: <<~YAML
              - !user OneOfAKind
              - !user OneOfAKind
            YAML
          )
          expect(response.code).to eq("422")
          expect(validation_status).to match("Invalid YAML")
          expect(validation_error_text).to match(/is declared more than once/)
          expect(validation_explanation).to match(//)
        end
      end

      context 'such as no-colon (an error-prone parse case)' do
        it 'returns Valid status, expected Error, and advice' do
          validate_policy(
            policy: <<~YAML
              - !user alice
              - !user bob
              - !policy
                id: test
                body
                - !user me
            YAML
          )
          expect(response.code).to eq("422")
          expect(validation_status).to match("Invalid YAML")
          expect(validation_error_text).to match(/could not find expected ':'/)
          expect(validation_explanation).to match(/This error can occur when/)
        end
      end

      context 'such as plain-alice (an error-prone parse case -- NoMethodError??)' do
        it 'returns Valid status, expected Error, and advice' do
          validate_policy(
            policy: <<~YAML
              - user alice
            YAML
          )
          expect(response.code).to eq("422")
          expect(validation_status).to match("Invalid YAML")
          expect(validation_error_text).to match(/undefined method/)
          expect(validation_explanation).to match(//)
        end
      end

      # Policy dry run includes the syntax/lexical validation, and now also
      # the business logic validation. Business logic fails when a database
      # exception is thrown during the policy loading process.
      context 'such as bob-not-found (from policy_load_errors.feature)' do
        it 'returns Valid status, expected Error, and advice' do
          apply_policy(
            policy: <<~YAML
              - !variable password

              - !permit
                role: !user bob
                privilege: [ execute ]
                resource: !variable password
            YAML
          )
          expect(response.code).to eq("404")
          body = JSON.parse(response.body)
          expect(body['error']['code']).to eq("not_found")
          expect(body['error']['message']).to eq("User 'bob' not found in account 'rspec'")
          expect(body['error']['target']).to eq("user")
          expect(body['error']['details']["code"]).to eq("not_found")
          expect(body['error']['details']["target"]).to eq("id")
          expect(body['error']['details']["message"]).to eq("rspec:user:bob")
        end
      end

      context 'such as blank-resource-id (from policy_load_errors.feature)' do
        it 'returns Valid status, expected Error, and advice' do
          validate_policy(
            policy: <<~YAML
              - !user bob

              - !permit
                role: !user bob
                privilege: [ execute ]
                resource:
            YAML
          )
          expect(response.code).to eq("422")
          expect(validation_status).to match("Invalid YAML")
          expect(validation_error_text).to match(/resource has a blank id/)
          expect(validation_explanation).to match(//)
        end
      end
    end
  end  
end

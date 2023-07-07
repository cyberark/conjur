# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Factories::CreateFromPolicyFactory) do
  let(:rest_client) { spy(RestClient) }
  let(:factory) { Factories::CreateFromPolicyFactory.new(http: rest_client) }
  # let(:simple_decoded_factory) { JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data)) }
  let(:simple_factory) do
    decoded_factory = JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data))
    DB::Repository::DataObjects::PolicyFactory.new(
      schema: decoded_factory['schema'],
      policy: Base64.decode64(decoded_factory['policy']),
      policy_branch: decoded_factory['policy_branch']
    )
  end

  describe('.call') do
    let(:response) do
      factory.call(
        factory_template: simple_factory,
        request_body: request,
        account: 'rspec',
        authorization: 'foo-bar'
      )
    end

    context 'when request is invalid' do
      context 'when request body is missing' do
        let(:request) { nil }
        it 'returns a failure response' do
          expect(response.success?).to be(false)
          expect(response.message).to eq('Request body must be JSON')
          expect(response.status).to eq(:bad_request)
        end
      end
      context 'when request body is empty' do
        let(:request) { '' }
        it 'returns a failure response' do
          expect(response.success?).to be(false)
          expect(response.message).to eq('Request body must be JSON')
          expect(response.status).to eq(:bad_request)
        end
      end
      context 'when request body is malformed JSON' do
        let(:request) { '{"foo": "bar }' }
        it 'returns a failure response' do
          expect(response.success?).to be(false)
          expect(response.message).to eq('Request body must be valid JSON')
          expect(response.status).to eq(:bad_request)
        end
      end
      context 'when request body is missing keys' do
        let(:request) { { id: 'foo' }.to_json }
        it 'returns a failure response' do
          expect(response.success?).to be(false)
          expect(response.message).to eq([{ message: "A value is required for 'branch'", key: 'branch' }])
          expect(response.status).to eq(:bad_request)
        end
      end
      context 'when request body is missing values' do
        let(:request) { { id: '', branch: 'foo' }.to_json }
        it 'returns a failure response' do
          expect(response.success?).to be(false)
          expect(response.message).to eq([{ message: "A value is required for 'id'", key: 'id' }])
          expect(response.status).to eq(:bad_request)
        end
      end
      context 'when request body is valid' do
        let(:request) { { id: 'foo', branch: 'bar' }.to_json }
        it 'submits the expected policy to Conjur' do
          expect(response.success?).to be(true)
          expect(rest_client).to have_received(:post).with('http://localhost:3000/policies/rspec/policy/bar', "- !user\n  id: foo\n", { 'Authorization' => 'foo-bar' })
        end
      end
    end
  end


  # describe('.validate_and_transform_request') do
  #   context 'with a simple factory' do
  #     let(:validated) do
  #       factory.validate_and_transform_request(
  #         schema: JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data))['schema'],
  #         params: params
  #       )
  #     end
  #     context 'when request body is missing' do
  #       let(:params) { nil }
  #       it 'returns a failure response' do
  #         expect(validated.success?).to be(false)
  #         expect(validated.message).to eq("Request body must be JSON")
  #         expect(validated.status).to eq(:bad_request)
  #       end
  #     end
  #     context 'when request body is malformed JSON' do
  #       let(:params) { '{"foo": "bar }' }
  #       it 'returns a failure response' do
  #         expect(validated.success?).to be(false)
  #         expect(validated.message).to eq("Request body must be valid JSON")
  #         expect(validated.status).to eq(:bad_request)
  #       end
  #     end
  #     context 'when request body is missing keys' do
  #       let(:params) { { id: 'foo' }.to_json }
  #       it 'returns a failure response' do
  #         expect(validated.success?).to be(false)
  #         expect(validated.message).to eq([{ message: "A value is required for 'branch'", key: "branch" }])
  #         expect(validated.status).to eq(:bad_request)
  #       end
  #     end
  #     context 'when request body is missing values' do
  #       let(:params) { { id: '', branch: 'foo' }.to_json }
  #       it 'returns a failure response' do
  #         expect(validated.success?).to be(false)
  #         expect(validated.message).to eq([{ message: "A value is required for 'id'", key: 'id' }])
  #         expect(validated.status).to eq(:bad_request)
  #       end
  #     end
  #     context 'when request body is valid' do
  #       let(:params) { { id: 'foo', branch: 'bar' }.to_json }
  #       it 'returns a failure response' do
  #         expect(validated.success?).to be(true)
  #         validated.bind {|result| expect(result).to eq({ 'id' => 'foo', 'branch' => 'bar' }) }
  #       end
  #     end
  #   end
  # end

  # describe('.render_and_apply_policy') do
  #   # Technically we should mock the Factories::Renderer to make this truely a unit
  #   # test. I'm including it here to avoid needing to maintain an extra interface.
  #   context 'The expected data is posted to the Conjur API' do
  #     it 'loads the approprate policy' do
  #       factory.render_and_apply_policy(
  #         policy_load_path: 'bar',
  #         policy_template: Base64.decode64(JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data))['policy']),
  #         variables: { 'id' => 'foo', 'branch' => 'bar' },
  #         account: 'cucumber',
  #         authorization: 'bar'
  #       )
  #       expect(rest_client).to have_received(:post).with('http://localhost:3000/policies/cucumber/policy/bar', "- !user\n  id: foo\n", {"Authorization"=>"bar"})
  #     end
  #   end

  #   context 'when response is valid' do
  #     let(:args) do
  #       ['http://localhost:3000/policies/cucumber/policy/bar', "- !user\n  id: foo\n", {"Authorization"=>"bar"}]
  #     end
  #     let(:response) { double(RestClient::Response, code: 201, body: 'foo') }
  #     let(:rest_client) do
  #       class_double(RestClient).tap do |double|
  #         allow(double).to receive(:post).with(*args).and_return(response)
  #       end
  #     end

  #     it 'returns successfully' do
  #       response = factory.render_and_apply_policy(
  #         policy_load_path: 'bar',
  #         policy_template: Base64.decode64(JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data))['policy']),
  #         variables: { 'id' => 'foo', 'branch' => 'bar' },
  #         account: 'cucumber',
  #         authorization: 'bar'
  #       )
  #       expect(response.success?).to be(true)
  #     end
  #   end
  # end

  # describe('.set_factory_variables') do
  #   let(:rest_client) do
  #     class_double(RestClient).tap do |double|
  #       rest_client_requests.each do |request, value|
  #         allow(double).to receive(:post).with(request, value, authorization).and_return(response)
  #       end
  #     end
  #   end
  #   let(:authorization) { { "Authorization"=>"baz" } }
  #   let(:rest_client_requests) do
  #     {
  #       'http://localhost:3000/secrets/cucumber/variable/foo%2Fbar%2Ffoo' => 'bing',
  #       'http://localhost:3000/secrets/cucumber/variable/foo%2Fbar%2Fbar' => 'bang'
  #     }
  #   end
  #   context 'when role is unauthorized' do
  #     let(:response) { double(RestClient::Response, code: 401) }
  #     it 'returns a failure response' do
  #       response = factory.set_factory_variables(
  #         schema_variables: { 'foo' => '', 'bar' => '' },
  #         factory_variables: { 'foo' => 'bing', 'bar' => 'bang' },
  #         variable_path: 'foo/bar',
  #         account: 'cucumber',
  #         authorization: 'baz'
  #       )
  #       expect(response.success?).to eq(false)
  #       expect(response.status).to eq(:unauthorized)
  #       expect(response.message).to eq(
  #         "Role is unauthorized to set variable: 'secrets/cucumber/variable/foo%2Fbar%2Ffoo'"
  #       )
  #     end
  #   end
  #   context 'when role lacks privilege' do
  #     let(:response) { double(RestClient::Response, code: 403) }
  #     it 'returns a failure response' do
  #       response = factory.set_factory_variables(
  #         schema_variables: { 'foo' => '', 'bar' => '' },
  #         factory_variables: { 'foo' => 'bing', 'bar' => 'bang' },
  #         variable_path: 'foo/bar',
  #         account: 'cucumber',
  #         authorization: 'baz'
  #       )
  #       expect(response.success?).to eq(false)
  #       expect(response.status).to eq(:forbidden)
  #       expect(response.message).to eq(
  #         "Role lacks the privilege to set variable: 'secrets/cucumber/variable/foo%2Fbar%2Ffoo'"
  #       )
  #     end
  #   end
  #   context 'when variable is not present' do
  #     let(:response) { double(RestClient::Response, code: 404, body: 'response') }
  #     it 'returns a failure response' do
  #       response = factory.set_factory_variables(
  #         schema_variables: { 'foo' => '', 'bar' => '' },
  #         factory_variables: { 'foo' => 'bing', 'bar' => 'bang' },
  #         variable_path: 'foo/bar',
  #         account: 'cucumber',
  #         authorization: 'baz'
  #       )
  #       expect(response.success?).to eq(false)
  #       expect(response.status).to eq(:bad_request)
  #       expect(response.message).to eq(
  #         "Failed to set variable: 'secrets/cucumber/variable/foo%2Fbar%2Ffoo'. Status Code: '404', Response: 'response'"
  #       )
  #     end
  #   end
  #   context 'when request is expected to be valid' do
  #     let(:response) { double(RestClient::Response, code: 201) }
  #     context 'when factory includes multiple variables' do
  #       it 'is successful' do
  #         response = factory.set_factory_variables(
  #           schema_variables: { 'foo' => '', 'bar' => '' },
  #           factory_variables: { 'foo' => 'bing', 'bar' => 'bang' },
  #           variable_path: 'foo/bar',
  #           account: 'cucumber',
  #           authorization: 'baz'
  #         )
  #         expect(response.success?).to eq(true)
  #       end
  #       context 'when factory includes a single variables' do
  #         it 'is successful' do
  #           response = factory.set_factory_variables(
  #             schema_variables: { 'foo' => '' },
  #             factory_variables: { 'foo' => 'bing', 'bar' => 'bang' },
  #             variable_path: 'foo/bar',
  #             account: 'cucumber',
  #             authorization: 'baz'
  #           )
  #           expect(response.success?).to eq(true)
  #         end
  #       end
  #       context 'when factory includes a variable not present in request' do
  #         it 'is successful' do
  #           response = factory.set_factory_variables(
  #             schema_variables: { 'foo' => '', 'bar' => '' },
  #             factory_variables: { 'foo' => 'bing' },
  #             variable_path: 'foo/bar',
  #             account: 'cucumber',
  #             authorization: 'baz'
  #           )
  #           expect(response.success?).to eq(true)
  #         end
  #       end
  #       context 'when request includes a value not present in the factory' do
  #         it 'is successful' do
  #           response = factory.set_factory_variables(
  #             schema_variables: { 'foo' => '' },
  #             factory_variables: { 'foo' => 'bing', 'bing' => 'foo' },
  #             variable_path: 'foo/bar',
  #             account: 'cucumber',
  #             authorization: 'baz'
  #           )
  #           expect(response.success?).to eq(true)
  #         end
  #       end
  #     end
  #   end
  # end

  # describe('.call') do
  #   context 'when policy factory is only a policy' do
  #     it 'loads the appropriate policy' do
  #       # factory.call(
  #       #   factory_template: JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data)),
  #       #   request_body: { 'id' => 'foo', 'branch' => 'bar' }.to_json
  #       # )
  #     end
  #   end
  # end
end

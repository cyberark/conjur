# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Factories::CreateFromPolicyFactory) do
  let(:rest_client) { spy(RestClient) }
  let(:factory) { Factories::CreateFromPolicyFactory.new(http: rest_client) }

  describe('.validate_and_transform_request') do
    context 'with a simple factory' do
      let(:validated) do
        factory.validate_and_transform_request(
          schema: JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data))['schema'],
          params: params
        )
      end
      context 'when request body is missing' do
        let(:params) { nil }
        it 'returns a failure response' do
          expect(validated.success?).to be(false)
          expect(validated.message).to eq("Request body must be JSON")
          expect(validated.status).to eq(:bad_request)
        end
      end
      context 'when request body is malformed JSON' do
        let(:params) { '{"foo": "bar }' }
        it 'returns a failure response' do
          expect(validated.success?).to be(false)
          expect(validated.message).to eq("Request body must be valid JSON")
          expect(validated.status).to eq(:bad_request)
        end
      end
      context 'when request body is missing keys' do
        let(:params) { { id: 'foo' }.to_json }
        it 'returns a failure response' do
          expect(validated.success?).to be(false)
          expect(validated.message).to eq([{ message: "A value is required for 'branch'", key: "branch" }])
          expect(validated.status).to eq(:bad_request)
        end
      end
      context 'when request body is missing values' do
        let(:params) { { id: '', branch: 'foo' }.to_json }
        it 'returns a failure response' do
          expect(validated.success?).to be(false)
          expect(validated.message).to eq([{ message: "A value is required for 'id'", key: 'id' }])
          expect(validated.status).to eq(:bad_request)
        end
      end
      context 'when request body is valid' do
        let(:params) { { id: 'foo', branch: 'bar' }.to_json }
        it 'returns a failure response' do
          expect(validated.success?).to be(true)
          validated.bind {|result| expect(result).to eq({ 'id' => 'foo', 'branch' => 'bar' }) }
        end
      end
    end
  end

  describe('.render_and_apply_policy') do
    # Technically we should mock the Factories::Renderer to make this truely a unit
    # test. I'm including it here to avoid needing to maintain an extra interface.
    context 'The expected data is posted to the Conjur API' do
      it 'loads the approprate policy' do
        factory.render_and_apply_policy(
          policy_load_path: 'bar',
          policy_template: Base64.decode64(JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data))['policy']),
          variables: { 'id' => 'foo', 'branch' => 'bar' },
          account: 'cucumber',
          authorization: 'bar'
        )
        expect(rest_client).to have_received(:post).with('http://localhost:3000/policies/cucumber/policy/bar', "- !user\n  id: foo\n", {"Authorization"=>"bar"})
      end
    end

    context 'when response is valid' do
      let(:args) do
        ['http://localhost:3000/policies/cucumber/policy/bar', "- !user\n  id: foo\n", {"Authorization"=>"bar"}]
      end
      let(:response) { double(RestClient::Response, code: 201, body: 'foo') }
      let(:rest_client) do
        class_double(RestClient).tap do |double|
          allow(double).to receive(:post).with(*args).and_return(response)
        end
      end

      it 'returns successfully' do
        response = factory.render_and_apply_policy(
          policy_load_path: 'bar',
          policy_template: Base64.decode64(JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data))['policy']),
          variables: { 'id' => 'foo', 'branch' => 'bar' },
          account: 'cucumber',
          authorization: 'bar'
        )
        expect(response.success?).to be(true)
      end
    end
  end

  describe('.set_factory_variables') do
    let(:rest_client) do
      class_double(RestClient).tap do |double|
        rest_client_requests.each do |request, value|
          allow(double).to receive(:post).with(request, value, authorization).and_return(response)
        end
      end
    end
    let(:authorization) { { "Authorization"=>"baz" } }
    let(:rest_client_requests) do
      {
        'http://localhost:3000/secrets/cucumber/variable/foo%2Fbar%2Ffoo' => 'bing',
        'http://localhost:3000/secrets/cucumber/variable/foo%2Fbar%2Fbar' => 'bang'
      }
    end
    context 'when role is unauthorized' do
      let(:response) { double(RestClient::Response, code: 401) }
      it 'returns a failure response' do
        response = factory.set_factory_variables(
          schema_variables: { 'foo' => '', 'bar' => '' },
          factory_variables: { 'foo' => 'bing', 'bar' => 'bang' },
          variable_path: 'foo/bar',
          account: 'cucumber',
          authorization: 'baz'
        )
        expect(response.success?).to eq(false)
        expect(response.status).to eq(:unauthorized)
        expect(response.message).to eq(
          "Role is unauthorized to set variable: 'secrets/cucumber/variable/foo%2Fbar%2Ffoo'"
        )
      end
    end
    context 'when role lacks privilege' do
      let(:response) { double(RestClient::Response, code: 403) }
      it 'returns a failure response' do
        response = factory.set_factory_variables(
          schema_variables: { 'foo' => '', 'bar' => '' },
          factory_variables: { 'foo' => 'bing', 'bar' => 'bang' },
          variable_path: 'foo/bar',
          account: 'cucumber',
          authorization: 'baz'
        )
        expect(response.success?).to eq(false)
        expect(response.status).to eq(:forbidden)
        expect(response.message).to eq(
          "Role lacks the privilege to set variable: 'secrets/cucumber/variable/foo%2Fbar%2Ffoo'"
        )
      end
    end
    context 'when variable is not present' do
      let(:response) { double(RestClient::Response, code: 404, body: 'response') }
      it 'returns a failure response' do
        response = factory.set_factory_variables(
          schema_variables: { 'foo' => '', 'bar' => '' },
          factory_variables: { 'foo' => 'bing', 'bar' => 'bang' },
          variable_path: 'foo/bar',
          account: 'cucumber',
          authorization: 'baz'
        )
        expect(response.success?).to eq(false)
        expect(response.status).to eq(:bad_request)
        expect(response.message).to eq(
          "Failed to set variable: 'secrets/cucumber/variable/foo%2Fbar%2Ffoo'. Status Code: '404', Response: 'response'"
        )
      end
    end
    context 'when request is expected to be valid' do
      let(:response) { double(RestClient::Response, code: 201) }
      context 'when factory includes multiple variables' do
        it 'is successful' do
          response = factory.set_factory_variables(
            schema_variables: { 'foo' => '', 'bar' => '' },
            factory_variables: { 'foo' => 'bing', 'bar' => 'bang' },
            variable_path: 'foo/bar',
            account: 'cucumber',
            authorization: 'baz'
          )
          expect(response.success?).to eq(true)
        end
        context 'when factory includes a single variables' do
          it 'is successful' do
            response = factory.set_factory_variables(
              schema_variables: { 'foo' => '' },
              factory_variables: { 'foo' => 'bing', 'bar' => 'bang' },
              variable_path: 'foo/bar',
              account: 'cucumber',
              authorization: 'baz'
            )
            expect(response.success?).to eq(true)
          end
        end
        context 'when factory includes a variable not present in request' do
          it 'is successful' do
            response = factory.set_factory_variables(
              schema_variables: { 'foo' => '', 'bar' => '' },
              factory_variables: { 'foo' => 'bing' },
              variable_path: 'foo/bar',
              account: 'cucumber',
              authorization: 'baz'
            )
            expect(response.success?).to eq(true)
          end
        end
        context 'when request includes a value not present in the factory' do
          it 'is successful' do
            response = factory.set_factory_variables(
              schema_variables: { 'foo' => '' },
              factory_variables: { 'foo' => 'bing', 'bing' => 'foo' },
              variable_path: 'foo/bar',
              account: 'cucumber',
              authorization: 'baz'
            )
            expect(response.success?).to eq(true)
          end
        end
      end
    end
  end

  describe('.call') do
    context 'when policy factory is only a policy' do
      let(:policy_factory) do
        decoded_factory = JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data))
        policy_factory = DB::Repository::DataObjects::PolicyFactory.new(
          policy: Base64.decode64(decoded_factory['policy']),
          policy_branch: decoded_factory['policy_branch'],
          schema: decoded_factory['schema'],
          version: 'v1',
          name: 'user',
          classification: 'core',
          description: ''
        )
      end

      it 'loads the appropriate policy' do
        factory.call(
          factory_template: policy_factory,
          request_body: { 'id' => 'foo', 'branch' => 'bar' }.to_json,
          account: 'cucumber',
          authorization: 'bar'
        )
        expect(rest_client).to have_received(:post).with('http://localhost:3000/policies/cucumber/policy/bar', "- !user\n  id: foo\n", {"Authorization"=>"bar"})
      end

      context 'when no JSON is present in request' do
        it 'responds with the appropriate failure' do
          response = factory.call(
            factory_template: policy_factory,
            request_body: nil,
            account: 'cucumber',
            authorization: 'bar'
          )
          expect(response.success?).to eq(false)
          expect(response.message).to eq('Request body must be JSON')
        end
      end
      context 'when JSON keys are missing in request' do
        it 'responds with the appropriate failure' do
          response = factory.call(
            factory_template: policy_factory,
            request_body: {}.to_json,
            account: 'cucumber',
            authorization: 'bar'
          )
          expect(response.success?).to eq(false)
          expect(response.message).to eq([
            { key: 'id', message: "A value is required for 'id'" },
            { key: 'branch', message: "A value is required for 'branch'" }
          ])
        end
      end
      context 'when JSON keys are missing values in the request' do
        it 'responds with the appropriate failure' do
          response = factory.call(
            factory_template: policy_factory,
            request_body: { id: '' }.to_json,
            account: 'cucumber',
            authorization: 'bar'
          )
          expect(response.success?).to eq(false)
          expect(response.message).to eq([
            { key: 'id', message: "A value is required for 'id'" },
            { key: 'branch', message: "A value is required for 'branch'" }
          ])
        end
      end
    end

    context 'when policy factory is policy and variables' do
      let(:policy_load_args) do
        [
          'http://localhost:3000/policies/cucumber/policy/conjur/authn-oidc',
          "- !policy\n  id: foo\n    body:\n  - !webservice\n\n  - !variable provider-uri\n  - !variable client-id\n  - !variable client-secret\n  - !variable redirect-uri\n  - !variable claim-mapping\n\n  - !group\n    id: authenticatable\n    annotations:\n      description: Group with permission to authenticate using this authenticator\n\n  - !permit\n    role: !group authenticatable\n    privilege: [ read, authenticate ]\n    resource: !webservice\n\n  - !webservice\n    id: status\n    annotations:\n      description: Web service for checking authenticator status\n\n  - !group\n    id: operators\n    annotations:\n      description: Group with permission to check the authenticator status\n\n  - !permit\n    role: !group operators\n    privilege: [ read ]\n    resource: !webservice status\n",
          { "Authorization"=>"bar" }
        ]
      end
      let(:provider_uri_args) do
        [
          'http://localhost:3000/secrets/cucumber/variable/conjur%2Fauthn-oidc%2Ffoo%2Fprovider-uri',
          'foo',
          { 'Authorization' => 'bar' }
        ]
      end
      let(:client_id_args) do
        [
          'http://localhost:3000/secrets/cucumber/variable/conjur%2Fauthn-oidc%2Ffoo%2Fclient-id',
          'bar',
          { 'Authorization' => 'bar' }
        ]
      end
      let(:client_secret_args) do
        [
          'http://localhost:3000/secrets/cucumber/variable/conjur%2Fauthn-oidc%2Ffoo%2Fclient-secret',
          'baz',
          { 'Authorization' => 'bar' }
        ]
      end
      let(:claim_mapping_args) do
        [
          'http://localhost:3000/secrets/cucumber/variable/conjur%2Fauthn-oidc%2Ffoo%2Fclaim-mapping',
          'bing',
          { 'Authorization' => 'bar' }
        ]
      end
      let(:policy_response) { double(RestClient::Response, code: 201, body: 'foo') }
      let(:variable_response) { double(RestClient::Response, code: 201) }
      let(:rest_client) do
        class_double(RestClient).tap do |double|
          allow(double).to receive(:post).with(*policy_load_args).and_return(policy_response)
          allow(double).to receive(:post).with(*provider_uri_args).and_return(variable_response)
          allow(double).to receive(:post).with(*client_id_args).and_return(variable_response)
          allow(double).to receive(:post).with(*client_secret_args).and_return(variable_response)
          allow(double).to receive(:post).with(*claim_mapping_args).and_return(variable_response)
        end
      end

      let(:factory_template) { JSON.parse(Base64.decode64(Factories::Templates::Authenticators::V1::AuthnOidc.data)) }
      it 'returns successfully' do
        policy_factory = DB::Repository::DataObjects::PolicyFactory.new(
          policy: Base64.decode64(factory_template['policy']),
          policy_branch: factory_template['policy_branch'],
          schema: factory_template['schema'],
          version: 'v1',
          name: 'authn-oidc',
          classification: 'authenticators',
          description: ''
        )

        result = factory.call(
          factory_template: policy_factory,
          request_body: {
            'id' => 'foo',
            'variables' => {
              'provider-uri' => 'foo',
              'client-id' => 'bar',
              'client-secret' => 'baz',
              'claim-mapping' => 'bing'
            }
          }.to_json,
          account: 'cucumber',
          authorization: 'bar'
        )
        expect(result.success?).to eq(true)
        expect(result.result).to eq('foo')
      end
    end
  end
end

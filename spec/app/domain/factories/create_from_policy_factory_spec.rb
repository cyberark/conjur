# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Factories::CreateFromPolicyFactory) do
  let(:rest_client) { spy(RestClient) }
  subject do
    Factories::CreateFromPolicyFactory
      .new(http: rest_client)
      .call(
        factory_template: factory_template,
        request_body: request,
        account: 'rspec',
        authorization: 'foo-bar'
      )
  end

  describe('.call') do
    context 'when using a simple factory' do
      let(:factory_template) do
        decoded_factory = JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data))
        DB::Repository::DataObjects::PolicyFactory.new(
          schema: decoded_factory['schema'],
          policy: Base64.decode64(decoded_factory['policy']),
          policy_branch: decoded_factory['policy_branch']
        )
      end
      context 'when request is invalid' do
        context 'when request body is missing' do
          let(:request) { nil }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq('Request body must be JSON')
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is empty' do
          let(:request) { '' }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq('Request body must be JSON')
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is malformed JSON' do
          let(:request) { '{"foo": "bar }' }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq('Request body must be valid JSON')
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is missing keys' do
          let(:request) { { id: 'foo' }.to_json }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "A value is required for 'branch'", key: 'branch' }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is missing values' do
          let(:request) { { id: '', branch: 'foo' }.to_json }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "A value is required for 'id'", key: 'id' }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when the request body includes invalid values' do
          let(:request) { { id: 'foo%', branch: 'b@r' }.to_json }
          it 'submits the expected policy to Conjur with invalid characters removed' do
            expect(subject.success?).to be(true)
            expect(rest_client).to have_received(:post).with('http://localhost:3000/policies/rspec/policy/br', "- !user\n  id: foo\n", { 'Authorization' => 'foo-bar' })
          end
        end
        context 'when request body is valid' do
          let(:request) { { id: 'foo', branch: 'bar' }.to_json }
          it 'submits the expected policy to Conjur' do
            expect(subject.success?).to be(true)
            expect(rest_client).to have_received(:post).with('http://localhost:3000/policies/rspec/policy/bar', "- !user\n  id: foo\n", { 'Authorization' => 'foo-bar' })
          end
          context 'when inputs include a hash (ex. for annotations)' do
            let(:request) { { id: 'foo', branch: 'bar', annotations: { 'foo' => 'bar', 'bing' => 'bang' } }.to_json }
            it 'submits the expected policy to Conjur' do
              expect(subject.success?).to be(true)
              expect(rest_client).to have_received(:post).with('http://localhost:3000/policies/rspec/policy/bar', "- !user\n  id: foo\n  annotations:\n    foo: bar\n    bing: bang\n", { 'Authorization' => 'foo-bar' })
            end
          end
          context 'when the Conjur API returns an error' do
            context 'when credentials are invalid' do
              it 'returns a failure response' do
                allow(rest_client).to receive(:post).and_raise(
                  RestClient::BadRequest.new(
                    double(RestClient::Response, code: 401, body: 'foo')
                  )
                )

                expect(subject.success?).to be(false)
                expect(subject.message[:message]).to eq('Authentication failed')
                expect(subject.status).to eq(:unauthorized)
              end
            end
            context 'when role is not permitted to apply the policy' do
              it 'returns a failure response' do
                allow(rest_client).to receive(:post).and_raise(
                  RestClient::BadRequest.new(
                    double(RestClient::Response, code: 403, body: 'foo')
                  )
                )

                expect(subject.success?).to be(false)
                expect(subject.message).to include({
                  message: "Applying generated policy to 'bar' is not allowed",
                  request_error: 'foo'
                })
                expect(subject.status).to eq(:forbidden)
              end
            end
            context 'when policy refers to invalid roles or resources' do
              it 'returns a failure response' do
                allow(rest_client).to receive(:post).and_raise(
                  RestClient::BadRequest.new(
                    double(RestClient::Response, code: 404, body: 'foo')
                  )
                )

                expect(subject.success?).to be(false)
                expect(subject.message[:message]).to eq("Unable to apply generated policy to 'bar'")
                expect(subject.status).to eq(:not_found)
              end
            end
            context 'when policy load is currently in progress' do
              it 'returns a failure response' do
                allow(rest_client).to receive(:post).and_raise(
                  RestClient::BadRequest.new(
                    double(RestClient::Response, code: 409, body: 'foo')
                  )
                )

                expect(subject.success?).to be(false)
                expect(subject.message[:message]).to eq("Failed to apply generated policy to 'bar'")
                expect(subject.status).to eq(:bad_request)
              end
            end
            context 'when a connection timeout error occurs' do
              it 'returns a failure response' do
                allow(rest_client).to receive(:post).and_raise(
                  RestClient::ServerBrokeConnection.new
                )

                expect(subject.success?).to be(false)
                expect(subject.message[:message]).to eq("Failed to apply generated policy to 'bar'")
                expect(subject.status).to eq(:bad_request)
              end
            end
          end
        end
      end
    end
    context 'when using a complex factory' do
      let(:factory_template) do
        decoded_factory = JSON.parse(Base64.decode64(Factories::Templates::Connections::V1::Database.data))
        DB::Repository::DataObjects::PolicyFactory.new(
          schema: decoded_factory['schema'],
          policy: Base64.decode64(decoded_factory['policy']),
          policy_branch: decoded_factory['policy_branch']
        )
      end
      let(:request) { { id: 'bar', branch: 'foo', variables: variables }.to_json }
      context 'when request body is missing values' do
        let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user' } }
        it 'returns a failure response' do
          expect(subject.success?).to be(false)
          expect(subject.message).to eq([{ message: "A value is required for '/variables/password'", key: '/variables/password' }])
          expect(subject.status).to eq(:bad_request)
        end
      end
      context 'when variable value is not a string' do
        context 'when value is an integer' do
          let(:variables) { { port: 1234, url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Validation error: '/variables/port' must be a string" }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when value is a boolean' do
          let(:variables) { { port: true, url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Validation error: '/variables/port' must be a string" }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when value is null' do
          let(:variables) { { port: nil, url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Validation error: '/variables/port' must be a string" }])
            expect(subject.status).to eq(:bad_request)
          end
        end
      end
      context 'when request body includes required values' do
        let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
        it 'applies policy and variables' do
          allow(rest_client).to receive(:post)
            .with(
              'http://localhost:3000/policies/rspec/policy/foo',
              "- !policy\n  id: bar\n  annotations:\n    factory: connections/database\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n\n  - !group consumers\n  - !group administrators\n\n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n\n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n\n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers\n",
              { 'Authorization' => 'foo-bar' }
            ).and_return(
              double(RestClient::Response, code: 201, body: '{"created_roles":{},"version":13}')
            )

          variables.each do |variable, value|
            allow(rest_client).to receive(:post)
              .with(
                "http://localhost:3000/secrets/rspec/variable/foo%2Fbar%2F#{variable}",
                value,
                { 'Authorization' => 'foo-bar' }
              ).and_return(
                double(RestClient::Response, code: 201, body: '')
              )
          end
          expect(subject.success?).to be(true)
        end
      end
      context 'when request body includes extra variable values' do
        let(:variables) { { foo: 'bar', port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
        # let(:request) { { id: 'bar', branch: 'foo', variables: variables }.to_json }
        it 'only saves variables defined in the factory' do
          allow(rest_client).to receive(:post)
            .with(
              'http://localhost:3000/policies/rspec/policy/foo',
              "- !policy\n  id: bar\n  annotations:\n    factory: connections/database\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n\n  - !group consumers\n  - !group administrators\n\n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n\n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n\n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers\n",
              { 'Authorization' => 'foo-bar' }
            ).and_return(
              double(RestClient::Response, code: 201, body: '{"created_roles":{},"version":13}')
            )

          variables.delete(:foo)
          variables.each do |variable, value|
            allow(rest_client).to receive(:post)
              .with(
                "http://localhost:3000/secrets/rspec/variable/foo%2Fbar%2F#{variable}",
                value,
                { 'Authorization' => 'foo-bar' }
              ).and_return(
                double(RestClient::Response, code: 201, body: '')
              )
          end
          expect(subject.success?).to be(true)
        end
      end
      context 'when role is not permitted to set variables' do
        let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
        context 'when role is not authorized' do
          it 'applies policy and variables' do
            allow(rest_client).to receive(:post)
              .with(
                'http://localhost:3000/policies/rspec/policy/foo',
                "- !policy\n  id: bar\n  annotations:\n    factory: connections/database\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n\n  - !group consumers\n  - !group administrators\n\n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n\n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n\n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers\n",
                { 'Authorization' => 'foo-bar' }
              ).and_return(
                double(RestClient::Response, code: 201, body: '{"created_roles":{},"version":13}')
              )

            allow(rest_client).to receive(:post)
              .with(
                "http://localhost:3000/secrets/rspec/variable/foo%2Fbar%2Furl",
                'http://localhost',
                { 'Authorization' => 'foo-bar' }
              ).and_raise(
                RestClient::BadRequest.new(
                  double(RestClient::Response, code: 401, body: '')
                )
              )

            expect(subject.success?).to be(false)
            expect(subject.message).to eq("Role is unauthorized to set variable: 'secrets/rspec/variable/foo%2Fbar%2Furl'")
            expect(subject.status).to eq(:unauthorized)
          end
        end
        context 'when role lacks required privileges' do
          it 'applies policy and variables' do
            allow(rest_client).to receive(:post)
              .with(
                'http://localhost:3000/policies/rspec/policy/foo',
                "- !policy\n  id: bar\n  annotations:\n    factory: connections/database\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n\n  - !group consumers\n  - !group administrators\n\n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n\n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n\n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers\n",
                { 'Authorization' => 'foo-bar' }
              ).and_return(
                double(RestClient::Response, code: 201, body: '{"created_roles":{},"version":13}')
              )

            allow(rest_client).to receive(:post)
              .with(
                "http://localhost:3000/secrets/rspec/variable/foo%2Fbar%2Furl",
                'http://localhost',
                { 'Authorization' => 'foo-bar' }
              ).and_raise(
                RestClient::BadRequest.new(
                  double(RestClient::Response, code: 403, body: '')
                )
              )

            expect(subject.success?).to be(false)
            expect(subject.message).to eq("Role lacks the privilege to set variable: 'secrets/rspec/variable/foo%2Fbar%2Furl'")
            expect(subject.status).to eq(:forbidden)
          end
        end
        context 'when variable is missing' do
          it 'fails with an appropriate error' do
            allow(rest_client).to receive(:post)
              .with(
                'http://localhost:3000/policies/rspec/policy/foo',
                "- !policy\n  id: bar\n  annotations:\n    factory: connections/database\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n\n  - !group consumers\n  - !group administrators\n\n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n\n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n\n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers\n",
                { 'Authorization' => 'foo-bar' }
              ).and_return(
                double(RestClient::Response, code: 201, body: '{"created_roles":{},"version":13}')
              )

            allow(rest_client).to receive(:post)
              .with(
                "http://localhost:3000/secrets/rspec/variable/foo%2Fbar%2Furl",
                'http://localhost',
                { 'Authorization' => 'foo-bar' }
              ).and_raise(
                RestClient::BadRequest.new(
                  double(RestClient::Response, code: 404, body: '')
                )
              )

            expect(subject.success?).to be(false)
            expect(subject.message).to eq("Failed to set variable: 'secrets/rspec/variable/foo%2Fbar%2Furl'. Status Code: '404', Response: ''")
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when there is a variable missing' do
          it 'applies policy and variables' do
            allow(rest_client).to receive(:post)
              .with(
                'http://localhost:3000/policies/rspec/policy/foo',
                "- !policy\n  id: bar\n  annotations:\n    factory: connections/database\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n\n  - !group consumers\n  - !group administrators\n\n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n\n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n\n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers\n",
                { 'Authorization' => 'foo-bar' }
              ).and_return(
                double(RestClient::Response, code: 201, body: '{"created_roles":{},"version":13}')
              )

            allow(rest_client).to receive(:post)
              .with(
                "http://localhost:3000/secrets/rspec/variable/foo%2Fbar%2Furl",
                'http://localhost',
                { 'Authorization' => 'foo-bar' }
              ).and_raise(
                RestClient::BadRequest.new(
                  double(RestClient::Response, code: 404, body: '')
                )
              )

            expect(subject.success?).to be(false)
            expect(subject.message).to eq("Failed to set variable: 'secrets/rspec/variable/foo%2Fbar%2Furl'. Status Code: '404', Response: ''")
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when there is a timeout attempting to set the secret' do
          it 'returns the appropriate error' do
            allow(rest_client).to receive(:post)
              .with(
                'http://localhost:3000/policies/rspec/policy/foo',
                "- !policy\n  id: bar\n  annotations:\n    factory: connections/database\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n\n  - !group consumers\n  - !group administrators\n\n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n\n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n\n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers\n",
                { 'Authorization' => 'foo-bar' }
              ).and_return(
                double(RestClient::Response, code: 201, body: '{"created_roles":{},"version":13}')
              )

            allow(rest_client).to receive(:post)
              .with(
                "http://localhost:3000/secrets/rspec/variable/foo%2Fbar%2Furl",
                'http://localhost',
                { 'Authorization' => 'foo-bar' }
              ).and_raise(
                RestClient::ServerBrokeConnection.new
              )

            expect(subject.success?).to be(false)
            expect(subject.message).to include({
              message: "Failed set variable 'secrets/rspec/variable/foo%2Fbar%2Furl'",
              request_error: 'Server broke connection'
            })
            expect(subject.status).to eq(:bad_request)
          end
        end
      end
    end
  end
end

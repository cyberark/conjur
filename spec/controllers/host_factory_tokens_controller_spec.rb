# frozen_string_literal: true

require 'spec_helper'
require 'time'

DatabaseCleaner.allow_remote_database_url = true
DatabaseCleaner.strategy = :truncation

describe HostFactoryTokensController, type: :request do
  before(:all) do
    # Start fresh
    DatabaseCleaner.clean_with(:truncation)

    # Init Slosilo key
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.create(role_id: 'rspec:user:admin')
  end

  # Allows API calls to be made as the admin user
  let(:admin_request_env) do
    token = Base64.strict_encode64(Slosilo["authn:rspec"].signed_token("admin").to_json)
    { 'HTTP_AUTHORIZATION' => "Token token=\"#{token}\"" }
  end

  def create_token
    post(
      "/host_factory_tokens",
      env: token_auth_header(role: current_user).merge(
        'RAW_POST_DATA' => create_token_payload,
        'ACCEPT' => "application/x.secretsmgr.v2beta+json",
        'CONTENT_TYPE' => "application/json"
      )
    )
  end

  def revoke_token
    delete(
      "/host_factory_tokens/#{host_factory_token}",
      env: token_auth_header(role: current_user).merge(
        'ACCEPT' => "application/x.secretsmgr.v2beta+json"
      )
    )
  end

  def apply_root_policy(account, policy_content:, expect_success: false)
    post("/policies/#{account}/policy/root", env: admin_request_env.merge({ 'RAW_POST_DATA' => policy_content }))
    return unless expect_success

    expect(response.code).to eq("201")
  end

  let(:test_policy) do
    <<~POLICY
      - !layer my-test
      - !host-factory
        id: test-factory
        annotations:
          description: Factory for testing
        layers: [ !layer my-test ]

      - !user tester

      - !permit
        role: !user tester
        privilege: [ read ]
        resource: !host-factory test-factory
    POLICY
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:tomorrow) { (Time.now + (24 * 60 * 60)).utc }
  let(:yesterday) { (Time.now - (24 * 60 * 60)).utc }

  let(:expiration) { tomorrow }
  let(:host_factory_resource) { Resource[host_factory_resource_id] }
  let(:host_factory_resource_id) { "rspec:host_factory:test-factory" }
  let(:cidr) { nil }
  let(:count) { nil }

  let(:create_token_payload) do
    {
      expiration: expiration,
      host_factory: host_factory_resource_id,
      cidr: cidr,
      count: count
    }.to_json
  end

  let(:host_factory_token) do
    HostFactoryToken.create(host_factory_token_options).token
  end

  let(:host_factory_token_options) do
    {
      resource: host_factory_resource,
      expiration: expiration
    }.tap do |options|
      options[:cidr] = cidr if cidr
    end
  end

  describe "#create" do
    before(:each) do
      apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
    end

    context "when the user has execute privilege on host factory" do
      it "creates a host factory token" do
        create_token
        expect(response.code).to eq("200")
      end

      context "when specifying cidr" do
        let(:cidr) { ["192.0.2.1"] }

        it "creates a host factory token with the specified cidr" do
          create_token
          expect(response.code).to eq("200")
          cidr_response = JSON.parse(response.body).first["cidr"]
          expect(cidr_response).to eq(["192.0.2.1/32"])
        end
      end

      context "when specifying count as an int" do
        let(:count) { 2 }

        it "creates an array of host factory tokens" do
          create_token
          expect(response.code).to eq("200")
          array = JSON.parse(response.body)
          expect(array.size).to eq(2)
        end
      end

      context "when specifying count as a string" do
        let(:count) { "2" }

        it "creates an array of host factory tokens" do
          create_token
          expect(response.code).to eq("200")
          array = JSON.parse(response.body)
          expect(array.size).to eq(2)
        end
      end

      context "when specifying expiration with just a date" do
        # Formats just the date portion into a string to be parsed
        let(:expiration) { tomorrow.to_date.iso8601 }

        it "creates an array of host factory tokens" do
          create_token
          expect(response.code).to eq("200")
          array = JSON.parse(response.body)
          expect(DateTime.iso8601(array.first["expiration"])).to eq(DateTime.iso8601(expiration))
        end
      end

      context "when the specified host factory does not exist" do
        let(:host_factory_resource_id) { "rspec:host_factory:non_existent" }

        it "returns a 404 code" do
          create_token
          expect(response.code).to eq("404")
        end
      end

      context "when the request parameters are invalid" do
        context "when using invalid resource kind" do
          let(:create_token_payload) do
            {
              expiration: expiration,
              user: host_factory_resource_id,
              cidr: cidr,
              count: count
            }.to_json
          end

          it "raises an argument error" do
            create_token
            expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"host_factory" } })
          end
        end

        context "when expiration parameter is missing" do
          let(:create_token_payload) do
            {
              host_factory: host_factory_resource_id,
              cidr: cidr,
              count: count
            }.to_json
          end

          it "returns a 422 code" do
            create_token
            expect(response.code).to eq("422")
            expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"expiration" } })
          end
        end

        context "when the token is using incorrect resource" do
          let(:host_factory_resource_id) { "rspec:user:tester" }

          it "raises an argument error" do
            create_token
            expect(response.code).to eq("422")
            expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Invalid resource kind: user" } })
          end
        end

        context "when the expiration parameter is invalid" do
          context "using a non-ISO8601 string" do
            let(:expiration) { "non-iso-string" }

            it "raises an argument error" do
              create_token
              expect(response.code).to eq("422")
              expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Input is invalid ISO8601 datetime string: #{expiration}" } })
            end
          end

          context "using an expired date" do
            let(:expiration) { "2017-08-04T22:27:20+00:00" }

            it "raises an argument error" do
              create_token
              expect(response.code).to eq("422")
              expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Value for parameter expiration must be in the future: #{DateTime.iso8601(expiration)}" } })
            end
          end

          context "using a non-string value" do
            let(:expiration) { 12345 }

            it "raises an argument error" do
              create_token
              expect(response.code).to eq("422")
              expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Input is invalid ISO8601 datetime string: #{expiration}" } })
            end
          end
        end

        context "when cidr is invalid" do
          let(:cidr) { ["ip.address"] }

          it "returns a 422 code" do
            create_token
            expect(response.code).to eq("422")
            expect(JSON.parse(response.body)).to eq({ "code"=>"422", "message"=>"Invalid IP address or CIDR range 'ip.address'" })
          end
        end
        context "when count parameter is invalid" do
          context "when count is a negative integer" do
            let(:count) { -1 }

            it "raises an argument error" do
              create_token
              expect(response.code).to eq("422")
              expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Invalid value for parameter 'count': #{count}" } })
            end
          end
          context "when count is a non-integer string" do
            let(:count) { "non-integer-input" }

            it "raises an argument error" do
              create_token
              expect(response.code).to eq("422")
              expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Invalid value for parameter 'count': #{count}" } })
            end
          end
          context "when count is zero" do
            let(:count) { 0 }

            it "raises an argument error" do
              create_token
              expect(response.code).to eq("422")
              expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Invalid value for parameter 'count': #{count}" } })
            end
          end
          context "when count is a float" do
            let(:count) { 1.5 }

            it "raises an argument error" do
              create_token
              expect(response.code).to eq("422")
              expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Invalid value for parameter 'count': #{count}" } })
            end
          end
          context "when count is a float string" do
            let(:count) { "1.5" }

            it "raises an argument error" do
              create_token
              expect(response.code).to eq("422")
              expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Invalid value for parameter 'count': #{count}" } })
            end
          end
        end
      end
    end

    context "when the user does not have execute privilege on host factory" do
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:tester') }

      it "returns a 403 code" do
        create_token
        expect(response.code).to eq("403")
      end
    end
  end

  describe '#destroy' do
    before(:each) do
      apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
    end

    context 'when the user has update privilege on host factory' do
      context 'token is valid' do
        it 'returns a 204 code' do
          revoke_token
          expect(response.code).to eq("204")
        end
      end

      context 'token is invalid' do
        let(:host_factory_token) { "non-token" }

        it 'returns a 404 code' do
          revoke_token
          expect(response.code).to eq("404")
        end
      end
    end

    context 'when the user does not have update privilege on host factory' do
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:tester') }

      it 'returns a 403 code' do
        revoke_token
        expect(response.code).to eq("403")
      end
    end
  end
end

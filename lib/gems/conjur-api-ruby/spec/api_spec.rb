require 'spec_helper'
require 'fakefs/spec_helpers'

describe Conjur::API do

  let(:account) { 'api-spec-acount' }
  before { allow(Conjur.configuration).to receive_messages account: account }

  shared_context "logged in", logged_in: true do
    let(:login) { "bob" }
    let(:token) { { 'data' => login, 'timestamp' => Time.now.to_s } }
    let(:remote_ip) { nil }
    let(:api_args) { [ token, { remote_ip: remote_ip } ] }
    subject(:api) { Conjur::API.new_from_token(*api_args) }
  end

  shared_context "logged in with an API key", logged_in: :api_key do
    include_context "logged in"
    let(:api_key) { "theapikey" }
    let(:api_args) { [ login, api_key, { remote_ip: remote_ip, account: account } ] }
    subject(:api) { Conjur::API.new_from_key(*api_args) }
  end

  shared_context "logged in with a token file", logged_in: :token_file do
    include FakeFS::SpecHelpers
    include_context "logged in"
    let(:token_file) { "token_file" }
    let(:api_args) { [ token_file, { remote_ip: remote_ip } ] }
    subject(:api) { Conjur::API.new_from_token_file(*api_args) }
  end

  def time_travel delta
    allow(api.authenticator).to receive(:gettime).and_wrap_original do |m|
      m[] + delta
    end
    allow(api.authenticator).to receive(:monotonic_time).and_wrap_original do |m|
      m[] + delta
    end
    allow(Time).to receive(:now).and_wrap_original do |m|
      m[] + delta
    end
  end

  describe '#token' do
    context 'with token file available', logged_in: :token_file do
      def write_token token
        File.write token_file, JSON.generate(token)
      end

      before do
        write_token token
      end

      it "reads the file to get a token" do
        expect(api.instance_variable_get("@token")).to eq(nil)
        expect(api.token).to eq(token)
        expect(api.credentials).to eq({ headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login })
      end

      context "after expiration" do
        it 'it reads a new token' do
          expect(Time.parse(api.token['timestamp'])).to be_within(5.seconds).of(Time.now)
          
          time_travel 6.minutes
          new_token = token.merge "timestamp" => Time.now.to_s
          write_token new_token
          
          expect(api.token).to eq(new_token)
        end
      end
    end

    context 'with API key available', logged_in: :api_key do
      it "authenticates to get a token" do
        expect(Conjur::API).to receive(:authenticate).with(login, api_key, account: account).and_return token

        expect(api.instance_variable_get("@token")).to eq(nil)
        expect(api.token).to eq(token)
        expect(api.credentials).to eq({ headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login })
      end

      context "after expiration" do

        shared_examples "it gets a new token" do
          it 'by refreshing' do
            allow(Conjur::API).to receive(:authenticate).with(login, api_key, account: account).and_return token
            expect(Time.parse(api.token['timestamp'])).to be_within(5.seconds).of(Time.now)
            
            time_travel 6.minutes
            new_token = token.merge "timestamp" => Time.now.to_s
            
            expect(Conjur::API).to receive(:authenticate).with(login, api_key, account: account).and_return new_token
            expect(api.token).to eq(new_token)
          end
        end

        it_should_behave_like "it gets a new token"
      end
    end

    context 'with no API key available', logged_in: true do
      it "returns the token used to create it" do
        expect(api.token).to eq token
      end

      it "doesn't try to refresh an old token" do
        expect(Conjur::API).not_to receive :authenticate
        api.token # vivify
        time_travel 6.minutes
        expect { api.token }.not_to raise_error
      end
    end
  end

  context "credential handling", logged_in: true do
    context "from token" do
      describe '#credentials' do
        subject { super().credentials }
        it { is_expected.to eq({ headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login }) }
      end
      
      context "with remote_ip" do
        let(:remote_ip) { "66.0.0.1" }
        describe '#credentials' do
          subject { super().credentials }
          it { is_expected.to eq({ headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"", :x_forwarded_for=>"66.0.0.1" }, username: login }) }
        end
      end
    end

    context "from logged-in RestClient::Resource" do
      let (:authz_header) { %Q{Token token="#{token_encoded}"} }
      let (:priv_header) { nil }
      let (:forwarded_for_header) { nil }
      let (:audit_roles_header) { nil }
      let (:audit_resources_header) { nil }
      let (:username) { 'bob' }
      subject { resource.conjur_api }

      shared_examples "it can clone itself" do
        it "has the authz header" do
          expect(subject.credentials[:headers][:authorization]).to eq(authz_header)
        end
        it "has the username" do
          expect(subject.credentials[:username]).to eq(username)
        end
      end

      let(:token_encoded) { Base64.strict_encode64(token.to_json) }
      let(:base_headers) { { authorization: authz_header } }
      let(:headers) { base_headers }
      let(:resource) { RestClient::Resource.new("http://example.com", { headers: headers })}
      context 'basic functioning' do
        it_behaves_like 'it can clone itself'
      end
      
      context "forwarded for" do
        let(:forwarded_for_header) { "66.0.0.1" }
        let(:headers) { base_headers.merge(x_forwarded_for: forwarded_for_header) }
        it_behaves_like 'it can clone itself'
      end
    end
  end

  describe "#role_from_username", logged_in: true do
    it "returns a user role when username is plain" do
      expect(Conjur::API.role_from_username(api, "plain-username", account).id).to eq("#{account}:user:plain-username")
    end

    it "returns an appropriate role kind when username is qualified" do
      expect(Conjur::API.role_from_username(api, "host/foo/bar", account).id).to eq("#{account}:host:foo/bar")
    end
  end

  describe "#current_role", logged_in: true do
    context "when logged in as user" do
      let(:login) { 'joerandom' }
      it "returns a user role" do
        expect(api.current_role(account).id).to eq("#{account}:user:joerandom")
      end
    end

    context "when logged in as host" do
      let(:host) { "somehost" }
      let(:login) { "host/#{host}" }
      it "returns a host role" do
        expect(api.current_role(account).id).to eq("#{account}:host:somehost")
      end
    end
  end

  describe 'url escapes' do
    let(:urls){[
        'foo/bar@baz',
        '/test/some group with spaces'
    ]}

    describe '#fully_escape' do
      let(:expected){[
        'foo%2Fbar%40baz',
        '%2Ftest%2Fsome%20group%20with%20spaces'
      ]}
      it 'escapes the urls correctly' do
        expect(urls.map{|u| Conjur::API.fully_escape u}).to eq(expected)
      end
    end
  end
end

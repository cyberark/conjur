require 'spec_helper'
require 'conjur/rack/user'

describe Conjur::Rack::User do
  let(:login){ 'admin' }
  let(:token){ {'data' => login} }
  let(:account){ 'acct' }
  let(:privilege) { nil }
  let(:remote_ip) { nil }
  let(:audit_roles) { nil }
  let(:audit_resources) { nil }
  
  subject(:user) { 
    described_class.new(token, account, 
      :privilege => privilege, 
      :remote_ip => remote_ip, 
      :audit_roles => audit_roles, 
      :audit_resources => audit_resources 
    )
  }
  
  it 'provides field accessors' do
    expect(user.token).to eq token
    expect(user.account).to eq account
    expect(user.conjur_account).to eq account
    expect(user.login).to eq login
  end
  
  describe '#roleid' do
    let(:login){ tokens.join('/') }

    context "when login contains one token" do
      let(:tokens) { %w(foobar) }

      it "is expanded to account:user:token" do
        expect(subject.roleid).to eq "#{account}:user:foobar"
      end
    end

    context "when login contains two tokens" do
      let(:tokens) { %w(foo bar) }

      it "is expanded to account:first:second" do
        expect(subject.roleid).to eq "#{account}:foo:bar"
      end
    end

    context "when login contains three tokens" do
      let(:tokens) { %w(foo bar baz) }

      it "is expanded to account:first:second/third" do
        expect(subject.roleid).to eq "#{account}:foo:bar/baz"
      end
    end
  end
  
  describe '#role' do
    let(:roleid){ 'the role id' }
    let(:api){ double('conjur api') }
    before do
      allow(subject).to receive(:roleid).and_return roleid
      allow(subject).to receive(:api).and_return api
    end
    
    it 'passes roleid to api.role' do
      expect(api).to receive(:role).with(roleid).and_return 'the role'
      expect(subject.role).to eq('the role')
    end
  end
  
  describe "#global_reveal?" do
    let(:api){ double "conjur-api" }
    before { allow(subject).to receive(:api).and_return(api) }

    context "with global privilege" do
      let(:privilege) { "reveal" }

      context "when not supported" do
        before { expect(api).not_to respond_to :global_privilege_permitted? }
        it "simply returns false" do
          expect(subject.global_reveal?).to be false
        end
      end

      context "when supported" do
        before do
          allow(api).to receive(:global_privilege_permitted?).with('reveal') { true }
        end
        it "checks the API function global_privilege_permitted?" do
          expect(subject.global_reveal?).to be true
          # The result is cached
          expect(api).not_to receive :global_privilege_permitted?
          subject.global_reveal?
        end
      end
    end

    context "without a global privilege" do
      it "simply returns false" do
        expect(subject.global_reveal?).to be false
      end
    end
  end
  
  describe '#api' do
    context "when given a class" do
      let(:cls){ double('API class') }
      it "calls cls.new_from_token with its token" do
        expect(cls).to receive(:new_from_token).with(token).and_return 'the api'
        expect(subject.api(cls)).to eq('the api')
      end
    end

    context 'when not given args' do
      let(:api) { double :api }
      before do
        allow(Conjur::API).to receive(:new_from_token).with(token).and_return(api)
      end

      it "builds the api from token" do
        expect(subject.api).to eq api
      end

      context "with remote_ip" do
        let(:remote_ip) { "the-ip" }
        it "passes the IP to the API constructor" do
          expect(Conjur::API).to receive(:new_from_token).with(token, 'the-ip').and_return(api)
          expect(subject.api).to eq api
        end
      end

      context "with privilege" do
        let(:privilege) { "elevate" }
        it "applies the privilege on the API object" do
          expect(api).to receive(:with_privilege).with("elevate").and_return "privileged api"
          expect(subject.api).to eq "privileged api"
        end
      end

      context "when audit supported" do
        before do
          # If we're testing on an API version that doesn't
          # support audit this method will be missing, so stub.
          unless Conjur::API.respond_to? :decode_audit_ids
            # not exactly a faithful reimplementation, but good enough for here
            allow(Conjur::API).to receive(:decode_audit_ids) {|x|[x]}
          end
        end

        context "with audit resource" do
          let (:audit_resources) { 'food:bacon' }
          it "applies the audit resource on the API object" do
            expect(api).to receive(:with_audit_resources).with(['food:bacon']).and_return('the api')
            expect(subject.api).to eq 'the api'
          end
        end

        context "with audit roles" do
          let (:audit_roles) { 'user:cook' }
          it "applies the audit role on the API object" do
            expect(api).to receive(:with_audit_roles).with(['user:cook']).and_return('the api')
            expect(subject.api).to eq 'the api'
          end
        end
      end

      context "when audit not supported" do
        before do
          expect(api).not_to respond_to :with_audit_resources
          expect(api).not_to respond_to :with_audit_roles
        end
        let (:audit_resources) { 'food:bacon' }
        let (:audit_roles) { 'user:cook' }
        it "ignores audit roles and resources" do
          expect(subject.api).to eq api
        end
      end
    end
  end

  context "with invalid type payload" do
    let(:token){ { "data" => :alice } }
    it "raises an error on trying to access the content" do
      expect{ subject.login }.to raise_error("Expecting String or Hash token data, got Symbol")
    end
  end

  context "with hash payload" do
    let(:token){ { "data" => { "login" => "alice", "capabilities" => { "fry" => "bacon" } } } }

    it "processes the login and attributes" do
      original_token = token.deep_dup

      expect(subject.login).to eq('alice')
      expect(subject.attributes).to eq({"capabilities" => { "fry" => "bacon" }})

      expect(token).to eq original_token
    end
  end

  context "with JWT token" do
    let(:token) { {"protected"=>"eyJhbGciOiJ0ZXN0IiwidHlwIjoiSldUIn0=",
 "payload"=>"eyJzdWIiOiJhbGljZSIsImlhdCI6MTUwNDU1NDI2NX0=",
 "signature"=>"dGVzdHNpZw=="} }

    it "processes the login and attributes" do
      original_token = token.deep_dup

      expect(subject.login).to eq('alice')

      # TODO: should we only pass unrecognized attrs here?
      expect(subject.attributes).to eq \
          'alg' => 'test',
          'iat' => 1504554265,
          'sub' => 'alice',
          'typ' => 'JWT'

      expect(token).to eq original_token
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'parallel'

DatabaseCleaner.strategy = :truncation

describe PoliciesController, type: :request do
  before(:all) do
    # init Slosilo key
    init_slosilo_keys("rspec")
  end

  before do
    allow_any_instance_of(described_class).to(
      receive_messages(current_user: current_user)
    )
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  # :reek:UtilityFunction is okay for this test util
  def variable(name)
    Resource["rspec:variable:#{name}"]
  end

  context '#post' do
    before { put_payload('[!variable preexisting]') }

    let(:policies_url) do
      # From config/routes.rb:
      # "/policies/:account/:kind/*identifier"
      '/policies/rspec/policy/root'
    end
    # TODO: Avoid duplication between here and "spec/support/authentication.rb"
    # This will require nontrivial refactoring and may be better waiting for a
    # larger overhaul of the test code.
    let(:token_auth_header) do
      bearer_token = token_key("rspec", "user").signed_token(current_user.login)
      token_auth_str =
        "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
      { 'HTTP_AUTHORIZATION' => token_auth_str }
    end
    def headers_with_auth(payload)
      token_auth_header.merge({ 'RAW_POST_DATA' => payload })
    end

    def post_payload(payload)
      post(policies_url, env: headers_with_auth(payload))
    end

    def put_payload(payload)
      put(policies_url, env: headers_with_auth(payload))
    end

    it "adds to an existing policy" do
      post_payload('[!variable added]')
      expect(variable('added')).to be
      expect(variable('preexisting')).to be
    end

    xit "does not return 500 when performed in parallel" do
      # TODO: Figure out how to fix the test env to turn this back on.
      #
      # Parallel is causing "config/environments/test.rb" to be run
      # twice. In particular this line:
      #
      #   config.audit_socket = Test::AuditSink.instance.address
      #
      # causing the error:
      #
      #   audit_sink.rb:22:in `delete': No such file or directory @ 
      #   apply2files - audit.sock (Errno::ENOENT)
      policies = Array.new(2) { |i| "[!variable test#{i}]" }
      Sequel::Model.db.disconnect # the children have to reconnect
      Parallel.each(policies, in_processes: 2) do |policy|
        post_payload(policy)
        expect(response.code).to_not be >= 500
      end
    end

    xit "allows making nonconflicting changes in parallel" do
      # I've thought about this long and hard and I'm not sure if we really
      # want this with the current interface. Because we return sequential
      # version to the client, even when there is no conflict the subsequent
      # transactions need to wait for the first one to commit. This wait,
      # however it is implemented, will necessarily hold resources (ie. the
      # HTTP and a database connection).
      # Perhaps it's smarter to let the client retry instead.
      #
      # Even if we do want to block transactions waiting, with the current
      # design the lock would have to be obtained for the full duration of
      # policy loading -- policy version (and the sequential number) is created
      # on the entry point to the update method. Fixing that would require
      # a significant refactoring of the policy loading code.
      # -- divide
      pending
      vars = Array.new(2) { |i| "test#{i}" }
      policies = vars.map { |var| "[!variable #{var}]" }
      Sequel::Model.db.disconnect # the children have to reconnect
      Parallel.each(policies, in_processes: 2) do |policy|
        post_payload(policy)
      end
      vars.each { |var| expect(variable(var)).to exist }
    end
  end

  context "Created and modified roles" do
    let(:created1) { create_host('rspec:host:created1', current_user).tap{|h| h.credentials[:api_key] = '123456'} }
    let(:updated1) { create_host('rspec:host:updated1', current_user).tap{|h| h.credentials[:api_key] = 'APIKEY'} }
    let(:updated2) { create_host('rspec:host:updated2', current_user).tap{|h| h.credentials[:api_key] = 'APIKEY'} }

    subject { described_class.new }

    it "update_roles modifies API key for associated credentials" do
      allow(Credentials).to receive(:where).with(api_key: 'APIKEY')
                                           .and_return([updated1.credentials, updated2. credentials])

      roles = subject.send(:update_roles)
      expect(roles.values.map{|r| r[:api_key]}).not_to include('APIKEY')
    end

    it "created and updated roles are merged" do
      policy_action = double('policy_action')
      allow(policy_action).to receive(:call)
      allow(policy_action).to receive(:new_roles).and_return([created1])
      allow(Credentials).to receive(:where).with(api_key: 'APIKEY')
                                           .and_return([updated1.credentials, updated2. credentials])
      roles = subject.send(:perform, policy_action)
      expect(roles.keys).to eq([created1.id, updated1.id, updated2.id])
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'parallel'

DatabaseCleaner.strategy = :truncation

describe PoliciesController, type: :request do
  before(:all) do
    # there doesn't seem to be a sane way to get this
    @original_database_cleaner_strategy =
      DatabaseCleaner.cleaners.first.strategy
        .class.name.downcase[/[^:]+$/].intern

    # we need truncation here because the tests span many transactions
    DatabaseCleaner.strategy = :truncation

    # init Slosilo key
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
  end

  after(:all) do
    DatabaseCleaner.strategy = @original_database_cleaner_strategy
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

  describe '#post' do
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
      bearer_token = Slosilo["authn:rspec"].signed_token(current_user.login)
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
end

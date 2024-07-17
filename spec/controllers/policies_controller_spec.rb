# frozen_string_literal: true

require 'spec_helper'
require 'spec_helper_policy'
require 'parallel'

DatabaseCleaner.strategy = :truncation

describe PoliciesController, type: :request do
  context 'when loading policy' do
    before(:all) do
      # there doesn't seem to be a sane way to get this
      @original_database_cleaner_strategy =
        DatabaseCleaner.connections.first.strategy
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

  context "when validating policy" do
    def variable(name)
      Resource["rspec:variable:#{name}"]
    end

    def user(name)
      Resource["rspec:user:#{name}"]
    end

    def error_msg_for_validate(resp)
      parsed_body = resp.parsed_body
      parsed_body['errors'][0]['message']
    end

    def error_msg_for_apply(resp)
      parsed_body = resp.parsed_body
      parsed_body['error']['details'][0]['message']
    end

    context 'with a valid policy' do
      let(:good_policy) do
        <<~POLICY
          - !user alice
          - !user bob
        POLICY
      end

      it "validates the policy without changing data" do
        validate_policy(policy: good_policy)
        expect(response.status).to eq(200)
        expect(user('alice')).not_to be
        expect(user('bob')).not_to be
      end

      it "loads the policy and makes database changes" do
        apply_policy(policy: good_policy)
        expect(response.status).to eq(201)
        expect(user('alice')).to be
        expect(user('bob')).to be
      end
    end

    context 'with a policy containing a yaml error' do
      let(:policy_with_missing_colon) do
        <<~POLICY
          - !user alice
          - !user bob
          - !policy
            id: test
            body
            - !user bob
        POLICY
      end

      it "returns error, including advice" do
        validate_policy(policy: policy_with_missing_colon)
        expect(response.status).to eq(422)
        msg = "could not find expected ':' while scanning a simple key\nThis error can occur when you have a missing ':' or missing space after ':'"
        expect(error_msg_for_validate(response)).to end_with(msg)
      end
    end

    context 'with a policy containing a conjur policy error' do
      let(:policy_with_bad_tags) do
        <<~POLICY
          - !policy
            id: my-policy
            body:
              !key1: "abcde"
              !key2: "fghij"
        POLICY
      end

      it "returns error, including advice" do
        validate_policy(policy: policy_with_bad_tags)
        expect(response.status).to eq(422)
        msg = "Unrecognized data type '!key1:'\nThe tag must be one of the following: !delete, !deny, !grant, !group, !host, !host-factory, !layer, !permit, !policy, !revoke, !user, !variable, !webservice"
        expect(error_msg_for_validate(response)).to end_with(msg)
      end
    end
  end
end

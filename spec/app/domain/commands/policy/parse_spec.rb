require 'spec_helper'
require './app/models/exceptions/record_not_found'

describe 'Commands::Policy::Parse' do
  ################ Policies to test ################
  let(:empty_policy) do
    <<~POLICY
    POLICY
  end

  let(:valid_policy) do
    <<~POLICY
      - !user alice
      - !user bob
    POLICY
  end

  let(:policy_with_yaml_error_no_colon) do
    <<~POLICY
      - !user alice
      - !user bob
      - !policy
        id: test
        body
        - !user bob
    POLICY
  end

  let(:policy_with_conjur_error_unrecognized_type) do
    <<~POLICY
      - !policy
        id: my-policy
        body:
          !key1: "abcde"
          !key2: "fghij"
    POLICY
  end

  let(:policy_with_yaml_error_bad_indent) do
    <<~POLICY
      - !policy
      \tid: my-policy
    POLICY
  end

  let(:policy_with_conjur_error_no_such_attribute) do
    <<~POLICY
      - !permit
        member:
        - !group developers
    POLICY
  end

  let(:policy_with_conjur_error_invalid_cidr) do
    <<~POLICY
      - !host
        id: serviceA
        restricted_to: an_invalid_cidr_string
    POLICY
  end

  let(:policy_with_conjur_error_type) do
    <<~POLICY
      - !permit
        member:
        - !group developers
    POLICY
  end

  let(:policy_with_conjur_missing_resource_id) do
    <<~POLICY
      - !user bob

      - !permit
        role: !user bob
        privilege: [ execute ]
        resource:
    POLICY
  end

  let(:policy_with_user_defined_twice) do
    <<~POLICY
      - !user TheOneAndOnly
      - !user TheOneAndOnly
    POLICY
  end

  let(:policy_with_missing_bang) do
    <<~POLICY
      - user Mallory
    POLICY
  end

  ############## End policies to test ##############

  let(:account) { 'rspec' }
  let(:owner)  { "#{account}:user:admin" }

  def parsed_policy(policy_text)
    Commands::Policy::Parse.new.call(
      account: account,
      policy_id: 'root',
      owner_id: owner,
      policy_text: policy_text,
      policy_filename: 'policy_filename.yml',
      root_policy: false
    )
  end

  def policy_err(policy_text)
    pp = Commands::Policy::Parse.new.call(
      account: account,
      policy_id: 'root',
      owner_id: owner,
      policy_text: policy_text,
      policy_filename: 'policy_filename.yml',
      root_policy: false
    )
    pp.error
  end

  context 'with different policy branches' do
    it 'resolves a simple policy as valid regardless of policy branch' do
      pp_root = Commands::Policy::Parse.new.call(
        account: account,
        policy_id: 'root', # <-
        owner_id: owner,
        policy_text: valid_policy,
        policy_filename: 'policy_filename.yml',
        root_policy: true
      )
      pp_nonroot = Commands::Policy::Parse.new.call(
        account: account,
        policy_id: 'something_else', # <-
        owner_id: owner,
        policy_text: valid_policy,
        policy_filename: 'policy_filename.yml',
        root_policy: false
      )
      expect(pp_root.records).not_to match_array([])
      expect(pp_root.error).to be_nil
      expect(pp_nonroot.records).not_to match_array([])
      expect(pp_nonroot.error).to be_nil
    end
  end

  context 'with the filename' do
    # Conjur::PolicyParser::Invalid reports the filename as an attribute
    it 'uses the name if provided' do
      pp = Commands::Policy::Parse.new.call(
        account: account,
        policy_id: 'root',
        owner_id: owner,
        policy_text: policy_with_conjur_error_unrecognized_type,
        policy_filename: 'policy_filename.yml', # <-
        root_policy: true
      )
      expect(pp.error.original_error.filename).to match('policy_filename.yml')
    end

    it 'uses the default "policy" as name if not provided' do
      pp = Commands::Policy::Parse.new.call(
        account: account,
        policy_id: 'root',
        owner_id: owner,
        policy_text: policy_with_conjur_error_unrecognized_type,
        policy_filename: nil, # <-
        root_policy: true
      )
      expect(pp.error.original_error.filename).to match("policy")
    end
  end

  context 'with no errors in the policy' do
    it 'returns records and a nil error' do
      pp = Commands::Policy::Parse.new.call(
        account: account,
        policy_id: 'something_else',
        owner_id: owner,
        policy_text: valid_policy,
        policy_filename: 'policy_filename.yml',
        root_policy: false
      )

      aggregate_failures "multiple ways for parse to fail" do
        expect(pp.records).not_to match_array([])
        expect(pp.error).to be_nil
      end
    end
  end

  # Be sure that Parse passes all expected error classes.
  # Verify they always result as EPE with non-null message and original_error
  context 'with errors in the policy' do
    it 'returns an EnhancedPolicyError and no records' do
      pp = Commands::Policy::Parse.new.call(
        account: account,
        policy_id: 'root',
        owner_id: owner,
        policy_text: policy_with_yaml_error_no_colon,
        policy_filename: 'policy_filename.yml',
        root_policy: false
      )
      expect(pp.records).to match_array([])
      expect(pp.error).to be_an_instance_of(Exceptions::EnhancedPolicyError)
    end

    # Try each of the error types rescued by Parse

    it 'returns a wrapped Conjur::PolicyParser::Invalid error' do
      err = policy_err(policy_with_conjur_error_unrecognized_type)

      aggregate_failures "finds an unrecognized data type" do
        expect(err.detail_message).to start_with("Unrecognized data type")
        expect(err.original_error).to be_an_instance_of(Conjur::PolicyParser::Invalid)
      end

      err = policy_err(policy_with_conjur_error_invalid_cidr)
      aggregate_failures "Invalid CIDR" do
        expect(err.detail_message).to start_with("Invalid IP address or CIDR range")
        expect(err.original_error).to be_an_instance_of(Conjur::PolicyParser::Invalid)
      end

      # err = policy_err(policy_with_conjur_missing_resource_id)
      # aggregate_failures "missing_resource_id" do
      #   expect(err.detail_message).to start_with("abc")
      #   expect(err.original_error).to be_an_instance_of(Conjur::PolicyParser::Invalid)
      # end
    end

    it 'returns a wrapped Psych::SyntaxError error' do
      err = policy_err(policy_with_yaml_error_no_colon)
      aggregate_failures "Missing colon" do
        expect(err.detail_message).to start_with("could not find expected ':'")
        expect(err.original_error).to be_an_instance_of(Psych::SyntaxError)
      end

      err = policy_err(policy_with_yaml_error_bad_indent)
      aggregate_failures "Bad indent" do
        expect(err.detail_message).to start_with("found character that cannot start any token")
        expect(err.original_error).to be_an_instance_of(Psych::SyntaxError)
      end
    end

    it 'returns a wrapped Exceptions::InvalidPolicyObject error' do
      # -------------------------------
      # Exceptions::InvalidPolicyObject : Not tested
      # -------------------------------
      # A test for this scenario is difficult to set up in this context.
      # However, the existence of the exception _is_ tested
      # in spec/models/loader/types.rb
    end

    it 'returns a wrapped Exceptions::RecordNotFound error' do
      # --------------------------
      # Exceptions::RecordNotFound : Not tested:
      # --------------------------
      # A test for this scenario is difficult to set up in this context.
      # Conditions that would trigger a RecordNotFound exception occur in the
      # controllers.  Controller tests should uncover any errors that might
      # be present for this exception.
    end

    it 'handles errors that occur in Resolver#resolve' do
      pp = parsed_policy(policy_with_missing_bang)
      aggregate_failures "deals with NoMethodError" do
        expect(pp.error).to be_an_instance_of(Exceptions::EnhancedPolicyError)
        expect(pp.error.original_error.original_error).to be_an_instance_of(NoMethodError)
        expect(pp.error.message).not_to eq("")
        # Error message is
        # undefined method `referenced_records' for "user Mallory":String
        expect(pp.error.detail_message).to start_with('undefined method `referenced_records')
      end

      pp = parsed_policy(policy_with_user_defined_twice)
      aggregate_failures "deals with RuntimeError" do
        expect(pp.error).to be_an_instance_of(Exceptions::EnhancedPolicyError)
        expect(pp.error.original_error.original_error).to be_an_instance_of(RuntimeError)
        expect(pp.error.message).not_to eq("")
        expect(pp.error.detail_message).to eq("user 'TheOneAndOnly@root' is declared more than once")
      end
    end
  end
end

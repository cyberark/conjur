# frozen_string_literal: true

require 'spec_helper'

describe Loader::Orchestrate do
  def policy_path(path)
    File.expand_path("loader_fixtures/#{path}", File.dirname(__FILE__))
  end

  def expectation_path(path)
    File.expand_path("loader_expectations/#{path}", File.dirname(__FILE__))
  end

  def load_base_policy(path)
    # Ensure we've created the admin user first
    role_user_admin

    policy_ver = save_policy(
      path,
      policy: Loader::Types.find_or_create_root_policy(account)
    )

    policy_action = Loader::ReplacePolicy.new(loader(policy_ver))
    policy_action.call
  end

  def save_policy(path, policy: resource_policy)
    policy_ver = PolicyVersion.new(
      policy: policy,
      role: role_user_admin,
      policy_text: File.read(policy_path(path)),
      delete_permitted: delete_permitted
    )
    policy_ver.validate
    expect(policy_ver.errors.to_a).to eq([])
    expect(policy_ver.valid?).to be_truthy
    policy_ver.save
  end

  def replace_policy_with(path)
    version = save_policy(path)
    policy_action = Loader::ReplacePolicy.new(loader(version))
    policy_action.call
  end

  def modify_policy_with(path)
    version = save_policy(path)
    policy_action = Loader::ModifyPolicy.new(loader(version))
    policy_action.call
  end

  def loader(policy_version)
    Loader::Orchestrate.new(
      policy_version,
      extension_repository: extension_repository_double,
      feature_flags: feature_flags_double
    )
  end

  let(:extension_repository_double) do
    instance_double(Conjur::Extension::Repository)
      .tap do |extension_repository_double|
        allow(extension_repository_double)
          .to receive(:extension)
          .with(kind: Loader::Orchestrate::POLICY_LOAD_EXTENSION_KIND)
          .and_return(policy_load_extension_double)
      end
  end

  let(:policy_load_extension_double) do
    instance_double(Conjur::Extension::Extension)
      .tap do |policy_load_extension_double|
        allow(policy_load_extension_double).to receive(:call)
      end
  end

  let(:feature_flags_double) do
    instance_double(Conjur::FeatureFlags::Features)
      .tap do |feature_flags_double|
        allow(feature_flags_double)
          .to receive(:enabled?)
          .with(:policy_load_extensions)
          .and_return(policy_load_extensions_enabled)
      end
  end

  let(:policy_load_extensions_enabled) { false }

  def verify_data(path)
    if ENV['DUMP_DATA']
      File.write(expectation_path(path), print_public)
    end
    expect(print_public).to eq(File.read(expectation_path(path)))
  end

  before do
    Role.where(Sequel.function("account", :role_id) => account).delete
    load_base_policy base_policy_path
  end

  let!(:schemata) { Schemata.new }
  let(:account) { 'rspec' }
  let(:resource_policy) { Resource["#{account}:policy:the-policy"] }
  let(:admin_id) { "#{account}:user:admin" }
  let(:role_user_admin) { ::Role[admin_id] || ::Role.create(role_id: admin_id) }
  let(:print_public) {
    Loader::Orchestrate.table_data(account, "#{schemata.primary_schema}__")
  }
  let(:delete_permitted) { true }

  context "with a minimal base policy" do
    let(:base_policy_path) { 'empty.yml' }
    it "loads the minimal policy" do
      expect(resource_policy).to be
      verify_data 'base/empty.txt'
    end

    context "with attempted policy update" do
      it "applies the policy update" do
        replace_policy_with 'simple.yml'
        verify_data 'updated/simple.txt'
      end
      it "creates a policy factory" do
        replace_policy_with 'policy_factory.yml'
        verify_data 'updated/policy_factory.txt'
      end
      it "creates a host factory" do
        replace_policy_with 'host_factory.yml'
        verify_data 'updated/host_factory.txt'
      end
      it "adds a layer to a host factory" do
        replace_policy_with 'host_factory.yml'
        replace_policy_with 'host_factory_new_layer.yml'
        verify_data 'updated/host_factory_new_layer.txt'
      end
      it "removes a layer from a host factory" do
        replace_policy_with 'host_factory_new_layer.yml'
        replace_policy_with 'host_factory.yml'
        verify_data 'updated/host_factory.txt'
      end
      it "doesn't affect a record in a different account" do
        Role.where(Sequel.function("account", :role_id) => 'acct1').delete
        Role.create(role_id: 'acct1:group:the-policy/group-a')
        replace_policy_with 'simple.yml'

        expect(Role['acct1:group:the-policy/group-a']).to be
        verify_data 'updated/simple_with_foreign_role.txt'
      end
      it "removes a record in a different account which is managed by the same policy" do
        Role.create(role_id: 'acct1:group:simple/group-a', policy_id: "#{account}:policy:the-policy")
        replace_policy_with 'simple.yml'

        expect(Role['acct1:group:simple/group-a']).to_not be
        verify_data 'updated/simple.txt'
      end
    end

    context "and two subsequent policy updates" do
      it "removed records are deleted" do
        replace_policy_with 'simple.yml'
        replace_policy_with 'extended.yml'
        verify_data 'updated/extended.txt'
      end
      it "removed records are kept" do
        modify_policy_with 'simple.yml'
        modify_policy_with 'extended.yml'
        verify_data 'updated/extended_without_deletion.txt'
      end
    end

    # The default state of the specs
    context "when policy load extensions are not enabled" do
      let(:policy_load_extensions_enabled) { false }

      it "does not load the policy load extensions" do
        expect(extension_repository_double)
          .not_to receive(:extension)

        replace_policy_with 'simple.yml'
        replace_policy_with 'extended.yml'
      end
    end

    context "when policy load extensions are enabled" do
      let(:policy_load_extensions_enabled) { true }

      it "loads the policy load extensions" do
        expect(extension_repository_double)
          .to receive(:extension)
          .with(kind: Loader::Orchestrate::POLICY_LOAD_EXTENSION_KIND)

        replace_policy_with 'simple.yml'
        replace_policy_with 'extended.yml'
      end

      it "triggers the expected callbacks" do
        expected_callbacks = [
          [:before_load_policy, { policy_version: anything }],
          [:before_delete, { policy_version: anything, schema_name: anything }],
          [:after_delete, { policy_version: anything, schema_name: anything }],
          [:before_update, { policy_version: anything, schema_name: anything }],
          [:after_update, { policy_version: anything, schema_name: anything }],
          [:before_insert, { policy_version: anything, schema_name: anything }],
          [:after_insert, { policy_version: anything, schema_name: anything }],
          [:after_create_schema, { policy_version: anything, schema_name: anything }],
          [:after_load_policy, { policy_version: anything }]
        ]

        expected_callbacks.each do |callback_args|
          expect(policy_load_extension_double)
            .to receive(:call)
            .with(callback_args[0], **callback_args[1])
        end

        replace_policy_with 'simple.yml'
        replace_policy_with 'extended.yml'
      end
    end
  end

  context "with a non-empty base policy" do
    let(:base_policy_path) { 'simple_base.yml' }
    context "and policy update" do
      it "applies the policy update" do
        replace_policy_with 'extended.yml'
        verify_data 'updated/extended_simple_base.txt'
      end
    end
  end
end

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
    require 'root_loader'
    RootLoader.load('rspec', policy_path(path))
  end

  def save_policy(path)
    policy_ver = PolicyVersion.new(
      policy: resource_policy,
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
    policy_action = Loader::ReplacePolicy.from_policy(version)
    policy_action.call
  end

  def modify_policy_with(path)
    version = save_policy(path)
    policy_action = Loader::ModifyPolicy.from_policy(version)
    policy_action.call
  end

  def verify_data(path)
    if ENV['DUMP_DATA']
      File.write(expectation_path(path), print_public)
    end
    expect(print_public).to eq(File.read(expectation_path(path)))
  end

  before do
    Role.where(Sequel.function("account", :role_id) => 'rspec').delete
    load_base_policy base_policy_path
  end

  let!(:schemata) { Schemata.new }
  let(:resource_policy) { Resource['rspec:policy:the-policy'] }
  let(:role_user_admin) { Role['rspec:user:admin'] }
  let(:print_public) {
    Loader::Orchestrate.table_data('rspec', "#{schemata.primary_schema}__")
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
        Role.create(role_id: 'acct1:group:simple/group-a', policy_id: 'rspec:policy:the-policy')
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

  context "with non-root user policy" do
    let(:base_policy_path) { 'empty.yml' }
    it "loads the minimal policy" do
      expect(resource_policy).to be
      verify_data 'base/empty.txt'
    end
    it "applies the policy update with non-root user" do
      status='sucess'
      begin
        ENV['CONJUR_ALLOW_USER_CREATION'] = 'false'
        replace_policy_with 'non_root_user.yml'
        # verify_data 'updated/simple.txt'
      rescue Exceptions::InvalidPolicyObject => exc
        status='failure'
      ensure
        ENV['CONJUR_ALLOW_USER_CREATION'] = 'true'
      end
      expect(status).to eq('failure')
    end
  end
end

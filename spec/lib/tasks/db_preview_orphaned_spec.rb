# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

Rails.application.load_tasks

describe "db:preview-orphaned" do
  def mock_stdout
    @old = $stdout
    $stdout = @fake = StringIO.new
  end

  def reset_stdout
    $stdout = @old
  end

  def load_base_policy(path)
    require 'root_loader'
    RootLoader.load('rspec', policy_path(path))
  end

  def policy_path(path)
    File.expand_path("loader_fixtures/#{path}", File.dirname(__FILE__))
  end

  let(:resource_policy) { Resource['rspec:policy:the-policy'] }
  let(:role_user_admin) { Role['rspec:user:admin'] }

  before(:each) do
    Role.where(Sequel.function("account", :role_id) => 'rspec').delete
    load_base_policy base_policy_path
    mock_stdout
  end

  after(:each) do
    Rake::Task["db:preview-orphaned"].reenable
    reset_stdout
  end

  context "with no roles" do
    let(:base_policy_path) { 'empty.yml' }
    it "prints out no roles found" do
      Rake::Task["db:preview-orphaned"].invoke
      expect(@fake.string).to eq("\nNo roles to remove\n")
    end
  end

  context "with good roles" do
    let(:base_policy_path) { 'CONJSE-1875-add.yml'}
    let(:resource_policy) { Resource['rspec:policy:root'] }

    it "prints out no roles found" do
      Rake::Task["db:preview-orphaned"].invoke
      expect(@fake.string).to eq("\nNo roles to remove\n")
    end
  end

  context "with bad roles" do
    let(:base_policy_path) { 'CONJSE-1875-add.yml'}
    let(:resource_policy) { Resource['rspec:policy:root'] }

    it "prints out roles that will be deleted" do
      Sequel::Model.db << "delete from resources where resource_id in ('rspec:user:sasha@myDemoApp', 'rspec:host:myDemoApp/app')"
      Rake::Task["db:preview-orphaned"].invoke
      expect(@fake.string).to eq("
Roles that will be removed because the parent policy has been removed
ID              TYPE
myDemoApp/app   host
sasha@myDemoApp user
")

      # Check that the roles are not deleted
      expect(Role['rspec:user:sasha@myDemoApp']).to be_a(Role)
      expect(Role['rspec:host:myDemoApp/app']).to be_a(Role)
    end

    it "deletes the roles" do
      Rake::Task["db:remove-orphaned"].invoke
      expect(@fake.string).to include("Deleting 2 roles that no longer exist in policy:")
      expect(@fake.string).to include("rspec:user:sasha@myDemoApp")
      expect(@fake.string).to include("rspec:host:myDemoApp/app")
      expect(Role['rspec:user:sasha@myDemoApp']).to be_nil
      expect(Role['rspec:host:myDemoApp/app']).to be_nil
    end
  end
end

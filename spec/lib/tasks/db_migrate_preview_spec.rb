# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

Rails.application.load_tasks

describe "db:migrate-preview" do
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

  before(:context) do
    Sequel::Model.db.alter_table :credentials do
      drop_foreign_key([:role_id])
    end
  end

  before(:each) do
    Role.where(Sequel.function("account", :role_id) => 'rspec').delete
    load_base_policy base_policy_path
    mock_stdout
  end

  after(:each) do
    Rake::Task["db:migrate-preview"].reenable
    reset_stdout
  end

  after(:context) do
    Sequel::Model.db.alter_table :credentials do
      add_foreign_key([:role_id], :roles, on_delete: :cascade)
    end
  end

  context "with no roles or credentials" do
    let(:base_policy_path) { 'empty.yml' }
    it "prints out no roles found" do
      expect(@fake.string).to eq("")
      Rake::Task["db:migrate-preview"].invoke
    end
  end

  context "with good roles and credentials" do
    let(:base_policy_path) { 'CONJSE-877-add.yml'}
    let(:resource_policy) { Resource['rspec:policy:root'] }

    it "prints out no roles found" do
      expect(@fake.string).to eq("")
      Rake::Task["db:migrate-preview"].invoke
    end
  end

  context "with good roles and bad credentials" do
    let(:base_policy_path) { 'CONJSE-877-add.yml'}
    let(:resource_policy) { Resource['rspec:policy:root'] }

    it "prints out credentials that will be deleted" do
      Sequel::Model.db << "delete from roles where role_id in ('rspec:user:sasha@myDemoApp', 'rspec:host:myDemoApp/app')"
      Rake::Task["db:migrate-preview"].invoke
      expect(@fake.string).to eq("
Credentials that will be removed because the associated role has been removed
ID              TYPE
myDemoApp/app   host
sasha@myDemoApp user
")
    end
  end

  context "with bad roles and good credentials" do
    let(:base_policy_path) { 'CONJSE-877-add.yml'}
    let(:resource_policy) { Resource['rspec:policy:root'] }

    it "prints out roles that will be deleted" do
      Sequel::Model.db << "delete from resources where resource_id in ('rspec:user:sasha@myDemoApp', 'rspec:host:myDemoApp/app')"
      Rake::Task["db:migrate-preview"].invoke
      expect(@fake.string).to eq("
Roles that will be removed because the parent policy has been removed
ID              TYPE
myDemoApp/app   host
sasha@myDemoApp user
")
    end
  end

  context "with bad roles and bad credentials" do
    let(:base_policy_path) { 'CONJSE-877-add.yml'}
    let(:resource_policy) { Resource['rspec:policy:root'] }

    it "prints out roles and credentials that will be deleted" do
      Sequel::Model.db << "delete from resources where resource_id = 'rspec:user:sasha@myDemoApp'"
      Sequel::Model.db << "delete from roles where role_id = 'rspec:host:myDemoApp/app'"
      Rake::Task["db:migrate-preview"].invoke
      expect(@fake.string).to eq("
Roles that will be removed because the parent policy has been removed
ID              TYPE
sasha@myDemoApp user

Credentials that will be removed because the associated role has been removed
ID            TYPE
myDemoApp/app host
")
    end
  end
end
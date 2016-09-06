require 'spec_helper'
require 'loader'

describe PolicyLoader do
  def policy_path path
    File.expand_path("loader_fixtures/#{path}", File.dirname(__FILE__))
  end
  def expectation_path path
    File.expand_path("loader_expectations/#{path}", File.dirname(__FILE__))
  end

  def load_base_policy path
    Loader.load 'rspec', policy_path(path)
  end

  def load_policy_update path
    version = PolicyVersion.new.tap do |version|
      version.policy = resource_policy
      version.role = role_user_admin
      version.owner = role_user_admin
      version.policy_text = File.read(policy_path(path))
      version.validate
      expect(version.errors.to_a).to eq([])
      expect(version.valid?).to be_truthy
      version.save
    end
    PolicyLoader.new(version).tap do |loader|
      loader.load
    end
  end

  def verify_data path
    if ENV['DUMP_DATA']
      File.write expectation_path(path), print_public
    end
    expect(print_public).to eq(File.read(expectation_path(path)))
  end

  before do
    DB[:roles].delete
    load_base_policy base_policy_path
  end

  let(:resource_policy) { Resource['rspec:policy:the-policy'] }
  let(:role_user_admin) { Role['rspec:user:admin'] }
  let(:print_public) {
    require 'table_print'
    io = StringIO.new
    tp.set :io, io
    tp.set :max_width, 100
    begin
      PolicyLoader::TABLES.each do |table|
        model = Sequel::Model("public__#{table}".to_sym)
        io.write "#{table}\n"
        tp *([ model.all ] + PolicyLoader::TABLE_EQUIVALENCE_COLUMNS[table.to_sym] + [ :policy_id ])
        io.write "\n"
      end
    ensure
      tp.clear :io
    end
    io.rewind
    io.read
  }

  context "with a minimal base policy" do
    let(:base_policy_path) { 'empty.yml' }
    it "loads the minimal policy" do
      expect(resource_policy).to be
      verify_data 'base/empty.txt'
    end

    context "and policy update" do
      it "applies the policy update" do
        load_policy_update 'simple.yml'
        verify_data 'updated/simple.txt'
      end
      it "doesn't affect a record in a different account" do
        Role.create(role_id: 'acct1:group:the-policy/group-a')
        load_policy_update 'simple.yml'
        verify_data 'updated/simple_with_foreign_role.txt'
      end
      it "removes a record in a different account which is managed by the same policy" do
        Role.create(role_id: 'acct1:group:simple/group-a', policy_id: 'rspec:policy:the-policy')
        load_policy_update 'simple.yml'
        verify_data 'updated/simple.txt'
      end
    end
  end

  context "with a non-empty base policy" do
    let(:base_policy_path) { 'simple.yml' }
    context "and policy update" do
      it "applies the policy update" do
        load_policy_update 'extended.yml'
        verify_data 'updated/extended_1.txt'
      end
    end
  end

  context "with a minimal base policy" do
    let(:base_policy_path) { 'empty.yml' }
    context "and policy update" do
      before do
        load_policy_update 'simple.yml'
      end
      context "a subsequent policy update" do
        before do
          load_policy_update 'extended.yml'
        end
        it "applies the policy update" do
          verify_data 'updated/extended_2.txt'
        end
        context "when deletion is disabled" do
          it "doesn't delete removed records"
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

require 'parallel'
DatabaseCleaner.strategy = :truncation

describe PoliciesController, type: :controller do
  describe '#post' do
    before { put '[!variable preexisting]' }

    it "adds to an existing policy" do
      post '[!variable added]'
      expect(variable('preexisting')).to exist
      expect(variable('added')).to exist
    end

    it "does not return 500 when performed in parallel" do
      policies = Array.new(2) { |i| "[!variable test#{i}]" }
      Sequel::Model.db.disconnect # the children have to reconnect
      Parallel.each policies, in_processes: 2 do |policy|
        post policy
        expect(response.code).to_not be >= 500
      end
    end

    it "allows making nonconflicting changes in parallel" do
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
      Parallel.each policies, in_processes: 2 do |policy|
        post policy
      end
      vars.each { |var| expect(variable(var)).to exist }
    end
  end

  before do
    allow_any_instance_of(described_class)
      .to receive_messages current_user: current_user
  end

  %i(put post patch).each do |meth|
    define_method meth do |text|
      super meth, text, account: 'rspec', identifier: 'root', kind: 'policy'
    end
  end

  # :reek:UtilityFunction is okay for this test util
  def variable name
    Resource["rspec:variable:#{name}"]
  end

  let(:current_user) { Role.find_or_create role_id: 'rspec:user:admin' }

  before(:all) do
    # there doesn't seem to be a sane way to get this
    @original_database_cleaner_strategy =
      DatabaseCleaner.connections.first.strategy
        .class.name.downcase[/[^:]+$/].intern
    # we need truncation here because the tests span many transactions
    DatabaseCleaner.strategy = :truncation
  end

  after(:all) { DatabaseCleaner.strategy = @original_database_cleaner_strategy }
end

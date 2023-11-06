# frozen_string_literal: true

# Tag options: roles, passwords, db
# Example usage: rspec spec/tasks/reset_password_spec.rb --tag roles

require 'spec_helper'
require 'stringio'
require_relative '../../bin/conjur-cli/commands'

Rails.application.load_tasks

describe 'reset_password.rake' do

  subject { Rake::Task['role:reset-password'] }

  # Stdout/Stderr are captured by doubles when running the rake file

  @orig_out = nil
  @orig_err = nil

  let(:stub_out) { StringIO.new }
  let(:stub_err) { StringIO.new }

  def capture_stdio
    @orig_out = $stdout
    @orig_err = $stderr
    $stdout = stub_out
    $stderr = stub_err
  end

  def restore_stdio
    $stderr = @orig_err
    $stdout = @orig_out
  end

  # Load Policy can be specific to each context

  def load_base_policy(account, path)
    require 'root_loader'
    RootLoader.load(account, policy_path(path))
  end

  def policy_path(path)
    File.expand_path("loader_fixtures/#{path}", File.dirname(__FILE__))
  end

  before(:example) do
    load_base_policy(account, base_policy_path)
    capture_stdio
  end

  after(:example) do
    restore_stdio
    # Allow rake to run the task again for subsequent tests
    subject.reenable
  end

  # Account and policy file providing roles

  test_account = 'rspec'
  policy_file = 'reset_password.yml'

  # Valid and nonexistent user roles
  valid_role_id = "#{test_account}:user:admin"
  nosuch_role_id = "#{test_account}:user:NoSuchUser"

  # Valid roles provided by the policy file
  group_role_id = "#{test_account}:group:developers"
  host_role_id = "#{test_account}:host:myapp-01"
  policy_role_id = "#{test_account}:policy:myapp"

  # All of the rake task failures return with SystemExit so we have to
  # expect that; otherwise, not all the examples will be executed.

  context 'with provided role', roles: true do
    let(:account) { test_account }
    let(:base_policy_path) { policy_file }

    it 'fails if role does not exist' do
      expect { subject.invoke(nosuch_role_id) }.to raise_error(SystemExit)
      expect(stub_err.string).to match(%r{error.*not exist})
    end

    it 'rejects a non-user host role' do
      expect { subject.invoke(host_role_id) }.to raise_error(SystemExit)
      expect(stub_err.string).to match(%r{error.*only user})
    end

    it 'rejects a non-user group role' do
      expect { subject.invoke(group_role_id) }.to raise_error(SystemExit)
      expect(stub_err.string).to match(%r{error.*is a 'group'})
    end
  end

  # To inform choices for validP1 and validP2 the
  # password complexity requirement states (in CONJ00046E):
  #   Choose a password that includes: 12-128 characters,
  #   2 uppercase letters, 2 lowercase letters,
  #   1 digit and 1 special character
  INVALIDP1 = 'BadPass'
  VALIDP1 = 'AnyOld3XYZ$%^Pass'
  VALIDP2 = 'Different3$%^Pass'

  # Stub IO::console.getpass so that we can inject our choice of passwords.

  let(:con_stub) { IO::console }

  context 'with 2 password entries', passwords: true do
    let(:account) { test_account }
    let(:base_policy_path) { policy_file }

    it 'rejects two differing password values' do
      allow(con_stub).to receive(:getpass).and_return(VALIDP1, VALIDP2)
      expect { subject.invoke(valid_role_id) }.to raise_error(SystemExit)
      expect(stub_err.string).to match(%r{.*error: passwords do not match})
    end
  
    it 'rejects an invalid password ' do
      allow(con_stub).to receive(:getpass).and_return(INVALIDP1, INVALIDP1)
      expect { subject.invoke(valid_role_id) }.to raise_error(SystemExit)
      expect(stub_err.string).to match(Errors::Conjur::InsufficientPasswordComplexity.new.to_s)
    end
  end

  # Method mocks:
  #   Commands::Credentials::ChangePassword
  #   Commands::Credentials::RotateApiKey
  # We only need each of these to fail to deny the credential update.
  # We'd like to be able to tell them apart in a failure report, so
  # by returning incomplete new obj calls the report will identify their
  # missing arguments.

  let(:db_stub) { Commands::Credentials::ChangePassword }
  let(:rot_stub) { Commands::Credentials::RotateApiKey }

  context 'with a database transaction', db: true do
    let(:account) { test_account }
    let(:base_policy_path) { policy_file }

    it 'rejects if the password change fails' do
      allow(db_stub).to receive(:new).and_return(db_stub.new)
      allow(con_stub).to receive(:getpass).and_return(VALIDP1, VALIDP1)
      expect { subject.invoke(valid_role_id) }.to raise_error(SystemExit)
      expect(stub_err.string).to match(%r{.*error: failed})
    end

    it 'rejects if the API Key rotation fails' do
      allow(rot_stub).to receive(:new).and_return(rot_stub.new)
      allow(con_stub).to receive(:getpass).and_return(VALIDP2, VALIDP2)
      expect { subject.invoke(valid_role_id) }.to raise_error(SystemExit)
      expect(stub_err.string).to match(%r{.*error: failed})
    end

    it 'is successful with a valid role, password, and transaction' do
      allow(con_stub).to receive(:getpass).and_return(VALIDP1, VALIDP1)
      subject.invoke(valid_role_id)
      confirmation = %r{.*Password changed.*New API key:}m
      expect(stub_out.string).to match(confirmation)
      expect(stub_err.string).to match("")
    end
  end

end

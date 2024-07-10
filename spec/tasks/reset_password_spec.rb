# frozen_string_literal: true

# Example usage: rspec spec/tasks/reset_password_spec.rb --tag roles
# Tags: roles, passwords, dbfailpw, dbfailrot, dbpass

require 'spec_helper'
require 'stringio'
require_relative '../../bin/conjur-cli/commands'

describe 'reset_password.rake' do

  # This unit test suite is premised on the assumption that we trust
  # the Conjur dependencies (because we provide our own unit tests and
  # end-to-end tests for them).  We also want to minimize the need to
  # keep real and double interfaces in sync.

  # Nonetheless, some doubles are used here:
  # - To capture text results from the rake command
  #   - double StringIO with stdio and stderr
  # - So that password entry can be automated
  #   - mock method IOConsole.getpass
  # - To mock methods and intentionally break them so that we can make
  #   the reset transaction fail
  #   - method Commands::Credentials::ChangePassword
  #   - method Commands::Credentials::RotateApiKey

  # This allows our broken methods
  RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

  subject { Rake::Task['role:reset-password'] }

  # Stdout/Stderr are captured by doubles when running the rake file.
  # Capture allows us to record output from the doubled/mocked resources,
  # Mute lets us suppress responses (from policy loading) that we don't need in the log.

  @orig_out = nil
  @orig_err = nil

  let(:stub_out) { StringIO.new }
  let(:stub_err) { StringIO.new }

  # Empty the given stream
  def readall(io)
    until io.eof?
      data << io.read(2048)
    end
  end

  def mute_stdio
    @orig_err = $stderr
    STDERR.reopen("/dev/null", "w")
  end

  def unmute_stdio
    $stderr = @orig_err
  end

  def capture_stdio
    @orig_out = $stdout
    @orig_err = $stderr

    # Empty the streams so that leftover output from one example won't contaminate the next.
    readall(stub_out)
    readall(stub_err)

    $stdout = stub_out
    $stderr = stub_err
  end

  def release_stdio
    $stderr = @orig_err
    $stdout = @orig_out
  end

  # Load Policy can be specific to each context
  # Note: suppress its stderr logging with mute_stdio.

  def load_base_policy(account, path)
    require 'root_loader'
    mute_stdio
    RootLoader.load(account, policy_path(path))
    unmute_stdio
  end

  def policy_path(path)
    File.expand_path("loader_fixtures/#{path}", File.dirname(__FILE__))
  end

  before(:example) do
    # Enable rake to run the task again for subsequent tests, and
    # force rake to pay attention to changed .rake sources
    subject.reenable
    load_base_policy(account, base_policy_path)
    capture_stdio
  end

  after(:example) do
    release_stdio
  end

  # Account and policy file providing roles

  test_account = 'cucumber'
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

  # To induce failures in these operations RSpec lets us define method
  # mocks that will raise exceptions of our choosing.  Though we might
  # expect to receive those exceptions here if the reset-password rake
  # allowed it, it doesn't and instead gracefully rescues them and
  # reports our chosen text through its stderr message.
  # That's adequate for us -- we can tailor our expect()s to look for it.

  context 'with a dual function transaction, first', dbfailpw: true do
    let(:account) { test_account }
    let(:base_policy_path) { policy_file }

    let(:pw_stub) { Commands::Credentials::ChangePassword }

    it 'rejects if the password change fails' do
      allow(con_stub).to receive(:getpass).and_return(VALIDP1, VALIDP1)
      allow(pw_stub).to receive(:new).and_raise("pw_is_stub")
      expect { subject.invoke(valid_role_id) }.to raise_error(SystemExit)

      # A single text match could be defined but this makes clear that other
      # failures are possible, too.
      expect(stub_err.string).to match(/pw_is_stub/)
      expect(stub_err.string).to match(%r{error: failed.*password})
    end
  end

  context 'with a dual function transaction, second', dbfailrot: true do
    let(:account) { test_account }
    let(:base_policy_path) { policy_file }

    let(:rot_stub) { Commands::Credentials::RotateApiKey }

    it 'rejects if the API Key rotation fails' do
      allow(con_stub).to receive(:getpass).and_return(VALIDP2, VALIDP2)
      allow(rot_stub).to receive(:new).and_raise("rot_is_stub")
      expect { subject.invoke(valid_role_id) }.to raise_error(SystemExit)

      expect(stub_err.string).to match(/rot_is_stub/)
      expect(stub_err.string).to match(%r{error: failed.*rotate})
    end
  end

  # The Expecting-Success (happy path) example could fail for any of
  # multiple reasons.  RSpec will abort as soon as it encounters the
  # SystemExit and we'll be denied reports of the actual causes.  By
  # aggregating the expectations we tell RSpec to allow all failure
  # causes to be reported.

  context 'with a completed database transaction', dbpass: true do
    let(:account) { test_account }
    let(:base_policy_path) { policy_file }

    it 'is successful with a valid role, password, and transaction' do
      allow(con_stub).to receive(:getpass).and_return(VALIDP1, VALIDP1)

      aggregate_failures "multiple ways that reset could fail" do
        expect { subject.invoke(valid_role_id) }.not_to raise_error
        expect(stub_err.string).not_to match(/^error/)
        expect(stub_out.string).to match(%r{.*password changed.*API key}im)
      end

    end
  end

end

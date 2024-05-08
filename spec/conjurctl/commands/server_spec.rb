require 'spec_helper'

require 'commands/server'

describe Commands::Server do

  let(:account) { "demo" }
  let(:password_from_stdin) { false }
  let(:file_name) { nil }
  let(:bind_address) { "0.0.0.0" }
  let(:port) { 80 }
  let(:no_migrate) { false }
  let(:no_rotation) { false }
  let(:no_authn_local) { false }

  let(:migrate_database) {
    double('DB::Migrate').tap do |migrate|
      allow(migrate).to receive(:call).with(preview: false)
    end
  }
  let(:connect_database) {
    double('ConnectDatabase').tap do |connect|
      allow(connect).to receive(:call)
    end
  }

  before do
    # Squash process forking for these tests as we have not implemented a full test
    # suite and it causes issues
    allow(Kernel).to receive(:exec)
    allow(Kernel).to receive(:system).and_return(true)
    allow(Process).to receive(:fork).and_yield
    allow(Process).to receive(:waitall).and_return(nil)
  end

  subject do
    Commands::Server.new(
      migrate_database: migrate_database,
      connect_database: connect_database
    )
  end

  def call_subject
    subject.call(
      account: account,
      password_from_stdin: password_from_stdin,
      file_name: file_name,
      bind_address: bind_address,
      port: port,
      no_migrate: no_migrate,
      no_rotation: no_rotation,
      no_authn_local: no_authn_local
    )
  end

  it "performs migrations" do
    expect(migrate_database).to receive(:call)

    call_subject
  end

  context "With the no_migrate variable set to true" do
    let(:no_migrate) { true }

    it "doesn't perform migrations" do
      expect(migrate_database).not_to receive(:call)

      call_subject
    end

    it "connects to the database" do
      expect(connect_database).to receive(:call)

      call_subject
    end
  end

  context "when rotation is disabled" do
    let(:no_rotation) { true }

    it "doesn't start the rotation service" do
      expect(subject).not_to receive(:exec).with("rake expiration:watch")
      call_subject
    end
  end

  context "when local authentication is disabled" do
    let(:no_authn_local) { true }

    it "doesn't start the local authentication service" do
      expect(subject).not_to receive(:exec).with("rake authn_local:run")
      call_subject
    end
  end
end

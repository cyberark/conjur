require 'spec_helper'

require 'commands/server'

describe Commands::Server do

  let(:account) { "demo" }
  let(:password_from_stdin) { false }
  let(:file_name) { nil }
  let(:bind_address) { "0.0.0.0" }
  let(:port) { 80 }
  let(:no_migrate) { false }

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
    allow(Process).to receive(:fork).and_return(nil)
    allow(Process).to receive(:waitall).and_return(nil)
  end

  def delete_account(name)
    system("conjurctl account delete #{name}")
  end

  after(:each) do
    delete_account("demo")
  end


  subject do
    Commands::Server.new(
      migrate_database: migrate_database,
      connect_database: connect_database
    ).call(
      account: account,
      password_from_stdin: password_from_stdin,
      file_name: file_name,
      bind_address: bind_address,
      port: port,
      no_migrate: no_migrate
    )
  end

  it "performs migrations" do
    expect(migrate_database).to receive(:call)

    subject
  end

  context "With the no_migrate variable set to true" do
    let(:no_migrate) { true }

    it "doesn't perform migrations" do
      expect(migrate_database).not_to receive(:call)

      subject
    end

    it "connects to the database" do
      expect(connect_database).to receive(:call)

      subject
    end
  end
end

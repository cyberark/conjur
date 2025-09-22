require "sequel"
require_relative '../../../bin/conjur-cli/commands/connect_database'

RSpec.describe(Commands::ConnectDatabase) do
  let(:database_url) { 'mock://does_not_matter' }
  let(:db_mock) { double('DB') }

  before do
    stub_const('ENV', ENV.to_hash.merge('DATABASE_URL' => database_url))
    allow_any_instance_of(Object).to receive(:sleep).with(1)
    allow(Sequel::Model).to receive(:db=)
    allow(Sequel::Model).to receive(:db).and_raise(Sequel::Error)
    allow(Sequel).to receive(:connect).and_return(db_mock)
    allow(db_mock).to receive(:disconnect)
    allow(db_mock).to receive(:[]).with('select 1')
  end

  it 'When database url is not set then exception should be raised' do
    expect(ENV).to receive(:[]).with("DATABASE_URL").and_return(nil)
    expect(Sequel).to_not receive(:connect)

    expect do
      described_class.new.call
    end.to raise_error(RuntimeError)
  end

  it 'When test query fails then newly created connection should be closed - do not leak connections' do
    testing_connection_counter = 0
    allow(db_mock).to receive(:[]).with('select 1') do
      testing_connection_counter += 1
      testing_connection_counter < 6 ? raise(StandardError, "DB unavailable") : double('result', first: 1)
    end
    expect(Sequel).to receive(:connect).exactly(6).times.and_return(db_mock)
    expect(db_mock).to receive(:disconnect).exactly(5).times

    expect do
      described_class.new.call
    end.not_to raise_error

    expect(testing_connection_counter).to eq(6)
  end

  it 'When there is already connection set on the model then do not create new connection' do
    allow(Sequel::Model).to receive(:db).and_return(true)
    expect(Sequel::Model).to_not receive(:db=)
    expect(Sequel).to_not receive(:connect)

    expect(described_class.new.call).to eq(true)
  end

  it 'When obtaining db connection fails then exception should be thrown' do
    expect(Sequel).to receive(:connect).exactly(30).times.and_return(nil)
    expect(Sequel::Model).to_not receive(:db=)
    expect(db_mock).to_not receive(:disconnect)

    expect do
      described_class.new.call
    end.to raise_error(RuntimeError)
  end

  it 'When db connection is created then Sequel::Model.db should be updated' do
    expect(Sequel).to receive(:connect).exactly(1).times
    expect(db_mock).to receive(:[]).with('select 1').and_return(double('result', first: 1))
    expect(db_mock).to_not receive(:disconnect)
    expect(Sequel::Model).to receive(:db=)

    expect(described_class.new.call).to eq(true)
  end
end

require 'spec_helper'
require 'stringio'

require 'commands/configuration/show'

describe Commands::Configuration::Show do
  def command_output(config, format:)
    output_stream = StringIO.new

    Commands::Configuration::Show.new(
      output_stream: output_stream
    ).call(
      conjur_config: config,
      output_format: format
    )

    output_stream.string
  end

  let(:conjur_config) { double(Conjur::ConjurConfig) }

  let(:source_trace) {
    {
      trusted_proxies: {
        source: { type: :defaults },
        value: []
      }
    }
  }

  before do
    allow(conjur_config).
      to receive(:to_source_trace).
      and_return(source_trace)
  end

  it 'outputs in JSON format' do
    expect(
      command_output(
        conjur_config,
        format: 'json'
      )
    ).to be_json_eql(<<~JSON).at_path('trusted_proxies')
      {
        "value": [],
        "source": "defaults"
      }
    JSON
  end

  it 'outputs in Text format' do
    expect(
      command_output(
        conjur_config,
        format: 'text'
      )
    ).to include(<<~TEXT)
      trusted_proxies:
        value: []
        source: defaults
    TEXT
  end

  it 'outputs in YAML format' do
    expect(
      command_output(
        conjur_config,
        format: 'yaml'
      )
    ).to include(<<~YAML)
      trusted_proxies:
        value: []
        source: defaults
    YAML
  end

  it 'errors on unknown formats' do
    expect do
      command_output(
        conjur_config,
        format: 'invalid'
      )
    end.to raise_error("Unknown configuration output format 'invalid'")
  end
end

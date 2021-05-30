require 'spec_helper'
require 'open3'

describe "conjurctl configuration show" do
  it "prints the configuration in JSON format" do
    stdout, _stderr, _status = Open3.capture3(
      "conjurctl configuration show --output json"
    )

    expect(stdout).to be_json_eql(<<~JSON).at_path('trusted_proxies')
      {
        "value": [],
        "source": "defaults"
      }
    JSON
  end

  it "prints the configuration in YAML format by default" do
    stdout, _stderr, _status = Open3.capture3(
      "conjurctl configuration show"
    )

    expect(stdout).to include(<<~YAML)
      ---
      trusted_proxies:
        value: []
        source: defaults
    YAML
  end

  it "outputs an error when given an invalid format" do
    _stdout, stderr, _status = Open3.capture3(
      "conjurctl configuration show --output invalid"
    )

    expect(stderr).to eq(
      "error: Unknown configuration output format 'invalid'\n"
    )
  end
end

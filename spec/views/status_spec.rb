require 'spec_helper'

RSpec.describe("status/index") do
  # The title text, 'Conjur Status', is a well-known
  # string that Conjur health probes are configured to
  # inspect the response for.
  it "includes the text 'Conjur Status'" do
    render

    expect(rendered).to include('Conjur Status')
  end

  it "includes the version number" do
    render

    version = File.read(File.expand_path("../../VERSION", File.dirname(__FILE__)))
    expect(rendered).to include("Version #{version}")
  end

  it "includes the version number in JSON" do
    render template: "status/index", formats: [:json]

    version = File.read(File.expand_path("../../VERSION", File.dirname(__FILE__)))
    expect(rendered).to include("\"version\":\"#{version}\"")
  end
end

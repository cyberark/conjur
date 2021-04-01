require 'spec_helper'

RSpec.describe("status/index") do
  # The title text, 'Conjur Status', is a well-known
  # string that Conjur health probes are configured to
  # inspect the response for.
  it "includes the text 'Conjur Status'" do
    render

    expect(rendered).to include('Conjur Status')
  end
end

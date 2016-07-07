require 'spec_helper'

describe 'routing to audit' do
  it "routes POST /audit to audit#inject_audit_event" do
    expect(post: '/audit').to route_to(
      controller: 'audit',
      action: 'inject_audit_event'
    )
  end
end

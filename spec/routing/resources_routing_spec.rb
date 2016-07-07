require 'spec_helper'

describe "routing for resources" do
  it "routes GET /authz/:account/resources/ to resources#index" do
    expect(get: '/authz/the-account/resources/').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'index'
    )
  end

  it "routes GET /authz/:account/resources/:kind to resources#index" do
    expect(get: '/authz/the-account/resources/chunky').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'index',
      kind: 'chunky'
    )
  end

  it "routes GET /authz/:account/resources/:kind/:identifier?check to resources#check_permission" do
    expect(get: '/authz/the-account/resources/foo/bar/baz?check').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'check_permission',
      kind: 'foo',
      identifier: 'bar/baz',
      check: nil
    )
  end

  it "routes GET /authz/:account/resources/:kind/:resource to resources#show" do
    expect(get: '/authz/the-account/resources/foo/bar').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'show',
      kind: 'foo',
      identifier: 'bar'
    )
  end
end

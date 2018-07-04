# frozen_string_literal: true

require 'spec_helper'

describe "routing for resources" do
  it "routes GET /resources/:account to resources#index" do
    expect(get: '/resources/the-account/').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'index'
    )
  end

  it "routes GET /resources/:account/:kind to resources#index" do
    expect(get: '/resources/the-account/chunky').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'index',
      kind: 'chunky'
    )
  end

  it "routes GET /resources/:account/:kind/:identifier?check to resources#check_permission" do
    expect(get: '/resources/the-account/foo/bar/baz?check').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'check_permission',
      kind: 'foo',
      identifier: 'bar/baz',
      check: nil
    )
  end

  it "routes GET /resources/:account/:kind/:identifier?permitted_roles to resources#permitted_roles" do
    expect(get: '/resources/the-account/foo/bar/baz?permitted_roles&privilege=fry').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'permitted_roles',
      kind: 'foo',
      privilege: 'fry',
      identifier: 'bar/baz',
      permitted_roles: nil
    )
  end

  it "routes GET /resources/:account/:kind/:resource to resources#show" do
    expect(get: '/resources/the-account/foo/bar').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'show',
      kind: 'foo',
      identifier: 'bar'
    )
  end
end

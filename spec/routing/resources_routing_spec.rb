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
    expect(get: '/resources/the-account/public_key').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'index',
      kind: 'public_key'
    )
  end

  it "routes GET /resources/:account/:kind/:identifier?check to resources#check_permission" do
    expect(get: '/resources/the-account/webservice/bar/baz?check').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'check_permission',
      kind: 'webservice',
      identifier: 'bar/baz',
      check: nil
    )
  end

  it "routes GET /resources/:account/:kind/:identifier?permitted_roles to resources#permitted_roles" do
    expect(get: '/resources/the-account/user/bar/baz?permitted_roles&privilege=fry').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'permitted_roles',
      kind: 'user',
      privilege: 'fry',
      identifier: 'bar/baz',
      permitted_roles: nil
    )
  end

  it "routes GET /resources/:account/:kind/:resource to resources#show" do
    expect(get: '/resources/the-account/variable/bar').to route_to(
      account: 'the-account',
      controller: 'resources',
      action: 'show',
      kind: 'variable',
      identifier: 'bar'
    )
  end

  it "does not route GET /resources/:account/:kind/:identifier for invalid kind" do
    expect(get: '/resources/the-account/invalid_kind/bar').not_to be_routable
  end
  
  context "for configuration kind" do
    it "routes GET /resources/:account/:kind/:resource to resources#show" do
      expect(get: '/resources/the-account/configuration/ldap-config').to route_to(
        account: 'the-account',
        controller: 'resources',
        action: 'show',
        kind: 'configuration',
        identifier: 'ldap-config'
      )
    end

    it "routes GET /resources/:account/:kind:identifier?check to resources#check_permission" do
      expect(get: '/resources/the-account/configuration/ldap-config?check').to route_to(
        account: 'the-account',
        controller: 'resources',
        action: 'check_permission',
        kind: 'configuration',
        identifier: 'ldap-config',
        check: nil
      )
    end

    it "routes GET /resources/:account/:kind/:identifier?permitted_roles to resources#permitted_roles" do
      expect(get: '/resources/the-account/configuration/ldap-config?permitted_roles').to route_to(
        account: 'the-account',
        controller: 'resources',
        action: 'permitted_roles',
        kind: 'configuration',
        identifier: 'ldap-config',
        permitted_roles: nil
      )
    end
  end
end

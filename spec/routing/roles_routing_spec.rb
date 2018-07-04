# frozen_string_literal: true

require 'spec_helper'

describe "routing from roles" do
  it "routes GET /roles/:account/:role to roles#show if :role is delimiter-containing" do
    [ '@', ';', ':', '=', '-', '_', ',' ].each do |delimiter|
      expect(get: "/roles/the-account/user/u#{delimiter}admin").to route_to(
        account: 'the-account',
        controller: 'roles',
        action: 'show',
        kind: 'user',
        identifier: "u#{delimiter}admin")
    end
  end
  
  it "routes GET /roles/:account/:role to roles#list_members" do
    expect(get: '/roles/the-account/user/admin').to route_to(
      account: 'the-account',
      controller: 'roles',
      action: 'show',
      kind: 'user',
      identifier: 'admin')
  end
  
  it "routes GET /roles/:account/:role?all to roles#all_memberships" do
    expect(get: '/roles/the-account/user/admin?all').to route_to(
      account: 'the-account',
      controller: 'roles',
      action: 'all_memberships',
      kind: 'user',
      identifier: 'admin',
      all: nil)
  end

  it "routes GET /roles/:account/:role?memberships to roles#direct_memberships" do
    expect(get: '/roles/the-account/user/admin?memberships').to route_to(
      account: 'the-account',
      controller: 'roles',
      action: 'direct_memberships',
      kind: 'user',
      identifier: 'admin',
      memberships: nil)
  end
end

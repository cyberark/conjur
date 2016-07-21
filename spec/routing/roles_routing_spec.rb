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
  
  it "routes GET /roles/:account/:role?all to roles#all_roles" do
    expect(get: '/roles/the-account/user/admin?all').to route_to(
      account: 'the-account',
      controller: 'roles',
      action: 'memberships',
      kind: 'user',
      identifier: 'admin',
      all: nil)
  end
  
  it "routes GET /roles/:account/:role?check to roles#check_permission" do
    expect(get: '/roles/the-account/user/admin?check').to route_to(
      account: 'the-account',
      controller: 'roles',
      action: 'check_permission',
      kind: 'user',
      identifier: 'admin',
      check: nil)
  end
end

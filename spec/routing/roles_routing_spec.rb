require 'spec_helper'

describe "routing from roles" do
  it "routes GET /authz/:account/roles/:role?members to roles#list_members if :role is delimiter-containing" do
    [ '@', ';', ':', '=', '-', '_', ',' ].each do |delimiter|
      expect(get: "/authz/the-account/roles/user/u#{delimiter}admin?members").to route_to(
        account: 'the-account',
        controller: 'roles',
        action: 'list_members',
        kind: 'user',
        identifier: "u#{delimiter}admin",
        members: nil)
    end
  end
  
  it "routes GET /authz/:account/roles/:role?members to roles#list_members" do
    expect(get: '/authz/the-account/roles/user/admin?members').to route_to(
      account: 'the-account',
      controller: 'roles',
      action: 'list_members',
      kind: 'user',
      identifier: 'admin',
      members: nil)
  end
  
  it "routes GET /authz/:account/roles/:role?all to roles#all_roles" do
    expect(get: '/authz/the-account/roles/user/admin?all').to route_to(
      account: 'the-account',
      controller: 'roles',
      action: 'all_roles',
      kind: 'user',
      identifier: 'admin',
      all: nil)
  end
  
  it "routes GET /authz/:account/roles/:role?check to roles#check_permission" do
    expect(get: '/authz/the-account/roles/user/admin?check').to route_to(
      account: 'the-account',
      controller: 'roles',
      action: 'check_permission',
      kind: 'user',
      identifier: 'admin',
      check: nil)
  end
end

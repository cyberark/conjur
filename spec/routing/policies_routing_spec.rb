# frozen_string_literal: true

require 'spec_helper'

describe "routing from policies" do
  it "routes GET /policies/:account/:kind/:identifier to policies#get for valid kind" do
    expect(get: '/policies/the-account/policy/myvar').to route_to(
                                                             account: 'the-account',
                                                             controller: 'policies',
                                                             action: 'get',
                                                             kind: 'policy',
                                                             identifier: 'myvar'
                                                           )
  end

  it "routes GET /policies/:account/:kind/:identifier to policies#get for invalid kind" do
    expect(get: '/policies/the-account/variable/mykey').not_to be_routable
  end

  it "does not route GET /policies/:account/:kind/:identifier for invalid kind" do
    expect(get: '/policies/the-account/invalid_kind/myid').not_to be_routable
  end

  it "routes GET /policies/:account/:kind/*identifier with delimiters in identifier" do
    [ '@', ';', ':', '=', '-', '_', ',' ].each do |delimiter|
      expect(get: "/policies/the-account/policy/my#{delimiter}id").to route_to(
                                                                          account: 'the-account',
                                                                          controller: 'policies',
                                                                          action: 'get',
                                                                          kind: 'policy',
                                                                          identifier: "my#{delimiter}id"
                                                                        )
    end
  end

  it "does not route GET /policies/:account/:kind/ for missing identifier" do
    expect(get: '/policies/the-account/variable/').not_to be_routable
  end

  it "does not route GET /policies/:account//identifier for missing kind" do
    expect(get: '/policies/the-account//myid').not_to be_routable
  end

  it "does not route GET /policies/:account/:kind/identifier for account with slashes" do
    expect(get: '/policies/the/account/policy/myid').not_to be_routable
  end

  it "does not route GET /policies/:account/:kind/identifier for account with encoded slashes" do
    expect(get: '/policies/the%2Faccount/policy/myid').not_to be_routable
  end

  it "routes GET /policies/:account/:kind/identifier for account with chars: % 2 F but not in sequence" do
    expect(get: '/policies/the%2aFaccount/policy/myid').to route_to(
      account: 'the*Faccount',
      controller: 'policies',
      action: 'get',
      kind: 'policy',
      identifier: 'myid',
    )
  end
end
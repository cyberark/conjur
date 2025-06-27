# frozen_string_literal: true

require 'spec_helper'

describe "routing from secrets" do
  it "routes GET /secrets/:account/:kind/:identifier to secrets#show for valid kind" do
    expect(get: '/secrets/the-account/variable/myvar').to route_to(
                                                             account: 'the-account',
                                                             controller: 'secrets',
                                                             action: 'show',
                                                             kind: 'variable',
                                                             identifier: 'myvar'
                                                           )
  end

  it "does not route GET /secrets/:account/:kind/:identifier to secrets#show for invalid kind" do
    expect(get: '/secrets/the-account/policy/myid').not_to be_routable
  end

  it "does not route GET /secrets/:account/:kind/:identifier to secrets#show for unknown kind" do
    expect(get: '/policies/the-account/invalid_kind/myid').not_to be_routable
  end

  it "routes GET /secrets/:account/:kind/:identifier with delimiters in identifier" do
    [ '@', ';', ':', '=', '-', '_', ',' ].each do |delimiter|
      expect(get: "/secrets/the-account/variable/my#{delimiter}id").to route_to(
                                                                          account: 'the-account',
                                                                          controller: 'secrets',
                                                                          action: 'show',
                                                                          kind: 'variable',
                                                                          identifier: "my#{delimiter}id"
                                                                        )
    end
  end

  it "does not route GET /secrets/:account/:kind/ for missing identifier" do
    expect(get: '/secrets/the-account/variable/').not_to be_routable
  end

  it "does not route GET /secrets/:account//identifier for missing kind" do
    expect(get: '/secrets/the-account//myid').not_to be_routable
  end

  it "does not route GET /secrets/:account/:kind/identifier for account with slashes" do
    expect(get: '/secrets/the/account/variable/myid').not_to be_routable
  end

  it "does not route GET /secrets/:account/:kind/identifier for account with encoded slashes" do
    expect(get: '/secrets/the%2Faccount/variable/myid').not_to be_routable
  end

  it "routes POST /secrets/:account/:kind/:identifier to secrets#create for valid kind" do
    expect(post: '/secrets/the-account/variable/myvar').to route_to(
                                                            account: 'the-account',
                                                            controller: 'secrets',
                                                            action: 'create',
                                                            kind: 'variable',
                                                            identifier: 'myvar'
                                                          )
  end

  it "does not route POST /secrets/:account/:kind/:identifier to secrets#create for any kind" do
    expect(post: '/secrets/the-account/policy/myid').not_to be_routable
  end

  it "does not route POST /secrets/:account/:kind/:identifier for unknown kind" do
    expect(post: '/policies/the-account/invalid_kind/myid').not_to be_routable
  end

  it "routes POST /secrets/:account/:kind/:identifier with delimiters in identifier" do
    [ '@', ';', ':', '=', '-', '_', ',' ].each do |delimiter|
      expect(post: "/secrets/the-account/variable/my#{delimiter}id").to route_to(
                                                                         account: 'the-account',
                                                                         controller: 'secrets',
                                                                         action: 'create',
                                                                         kind: 'variable',
                                                                         identifier: "my#{delimiter}id"
                                                                       )
    end
  end

  it "does not route POST /secrets/:account/:kind/ for missing identifier" do
    expect(post: '/secrets/the-account/variable/').not_to be_routable
  end

  it "does not route POST /secrets/:account//identifier for missing kind" do
    expect(post: '/secrets/the-account//myid').not_to be_routable
  end

  it "does not route POST /secrets/:account/:kind/identifier for account with slashes" do
    expect(post: '/secrets/the/account/variable/myid').not_to be_routable
  end

  it "does not route POST /secrets/:account/:kind/identifier for account with encoded slashes" do
    expect(post: '/secrets/the%2Faccount/variable/myid').not_to be_routable
  end
end

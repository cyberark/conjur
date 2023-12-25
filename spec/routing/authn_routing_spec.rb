# frozen_string_literal: true

require 'spec_helper'

describe "routing for authentication", :type => :routing do
  it "routes POST /authn/the-account/kevin.gilpin@inscitiv.com/authenticate to authenticate#authenticate" do
    expect(post: '/authn/the-account/kevin.gilpin@inscitiv.com/authenticate').to route_to(
      controller: 'authenticate',
      action: 'authenticate',
      account: 'the-account',
      authenticator: 'authn',
      id: 'kevin.gilpin@inscitiv.com'
    )
  end

  #API is removed
  xit "routes PUT /authn/the-account/password to credentials#update_password" do
    expect(put: '/authn/the-account/password').to route_to(
      controller: 'credentials',
      account: 'the-account',
      authenticator: 'authn',
      action: 'update_password'
    )
  end
end

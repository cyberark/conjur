require 'spec_helper'

describe "routing for Users", :type => :routing do
  it "routes POST /authn/users/kevin.gilpin@inscitiv.com/authenticate to authenticate#authenticate" do
    expect(post: '/authn/users/kevin.gilpin@inscitiv.com/authenticate').to route_to(
      controller: 'authenticate',
      action: 'authenticate',
      id: 'kevin.gilpin@inscitiv.com'
    )
  end
  
  it "routes GET /authn/usersto authn_users#show" do
    expect(get: '/authn/users').to route_to(
      controller: 'authn_users',
      action: 'show'
    )
  end

  it "routes PUT /authn/users/password to authn_users#update_password" do
    expect(put: '/authn/users/password').to route_to(
      controller: 'authn_users',
      action: 'update_password'
    )
  end
end

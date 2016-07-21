require 'spec_helper'

describe "routing for authentication", :type => :routing do
  it "routes POST /authn/kevin.gilpin@inscitiv.com/authenticate to authenticate#authenticate" do
    expect(post: '/authn/kevin.gilpin@inscitiv.com/authenticate').to route_to(
      controller: 'authenticate',
      action: 'authenticate',
      id: 'kevin.gilpin@inscitiv.com'
    )
  end
  
  it "routes PUT /authn/password to credentials#update_password" do
    expect(put: '/authn/password').to route_to(
      controller: 'credentials',
      action: 'update_password'
    )
  end
end

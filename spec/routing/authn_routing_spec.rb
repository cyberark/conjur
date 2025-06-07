# frozen_string_literal: true

require 'spec_helper'

describe "routing for authentication", :type => :routing do
  it "routes POST /authn/the-account/kevin.gilpin@inscitiv.com/authenticate to authenticate#authenticate" do
    expect(post: '/authn/the-account/kevin.gilpin@inscitiv.com/authenticate').to route_to(
      controller: 'authenticate',
      action: 'authenticate_via_post',
      account: 'the-account',
      authenticator: 'authn',
      id: 'kevin.gilpin@inscitiv.com'
    )
  end

  it "routes PUT /authn/the-account/password to credentials#update_password" do
    expect(put: '/authn/the-account/password').to route_to(
      controller: 'credentials',
      account: 'the-account',
      authenticator: 'authn',
      action: 'update_password'
    )
  end

  it 'routes POST /authn-k8s/meow/rspec/host%2Fh-618b9d046c6a9ab192994f17/authenticate to authenticate#authenticate' do
    expect(post: '/authn-k8s/meow/rspec/host%2Fh-618b9d046c6a9ab192994f17/authenticate').to route_to(
      controller: 'authenticate',
      action: 'authenticate',
      service_id: 'meow',
      authenticator: 'authn-k8s',
      id: 'host/h-618b9d046c6a9ab192994f17',
      account: 'rspec'
    )
  end

  it 'routes POST /authn/new_account@example.com/admin/authenticate to authenticate#authenticate' do
    expect(post: 'authn/new_account@example.com/admin/authenticate').to route_to(
      controller: 'authenticate',
      action: 'authenticate_via_post',
      account: 'new_account@example.com',
      authenticator: 'authn',
      id: 'admin'
    )
  end
end

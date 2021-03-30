# frozen_string_literal: true

require 'spec_helper'

describe Conjur::TrustedProxyFilter do
  it "raises an exception when created with invalid IP addresses" do
    env = { 'TRUSTED_PROXIES' => 'invalid-ip' }

    expect do
      Conjur::TrustedProxyFilter.new(env: env)
    end.to raise_error(Errors::Conjur::InvalidTrustedProxies)
  end

  it "does not raise an exception when created with valid IP addresses" do
    env = { 'TRUSTED_PROXIES' => '127.0.0.1' }

    expect do
      Conjur::TrustedProxyFilter.new(env: env)
    end.not_to raise_error
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe Conjur::TrustedProxyFilter do
  it "raises an exception when created with invalid IP addresses" do
    config = Conjur::ConjurConfig.new(trusted_proxies: 'invalid-ip')

    expect {
      Conjur::TrustedProxyFilter.new(config: config)
    }.to raise_error(Errors::Conjur::InvalidTrustedProxies)
  end

  it "does not raise an exception when created with valid IP addresses" do
    config = Conjur::ConjurConfig.new(trusted_proxies: '127.0.0.1')

    expect {
      Conjur::TrustedProxyFilter.new(config: config)
    }.not_to raise_error
  end
end

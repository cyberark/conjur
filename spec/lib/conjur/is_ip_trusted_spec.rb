# frozen_string_literal: true

require 'spec_helper'

describe Conjur::IsIpTrusted do

  let(:config) { Conjur::ConjurConfig.new(trusted_proxies: '127.0.0.1,::1') }

  it "does not raise an exception when created with valid IP addresses" do
    expect {
      Conjur::IsIpTrusted.new(config: config)
    }.not_to raise_error
  end

  it "Configuration IPs are considered as trusted IPS" do
    is_trusted = Conjur::IsIpTrusted.new(config: config).call("127.0.0.1")
    expect(is_trusted).to eq(true)
  end

  it "Edge IPs are considered as trusted IPS" do
    Edge.new_edge(max_edges: 10, name: "edgy", ip: "1.1.1.1")

    is_trusted = Conjur::IsIpTrusted.new(config: config).call("1.1.1.1")
    expect(is_trusted).to eq(true)
  end

  it "DB is not queried too often" do
    is_ip_trusted = Conjur::IsIpTrusted.new(config: config, disable_cache: false)
    Edge.new_edge(max_edges: 10, name: "edgy", ip: "1.1.1.1")
    is_trusted = is_ip_trusted.call("1.1.1.1")
    # Expecting false since it indicates that cache is used and not actual DB
    expect(is_trusted).to eq(false)
  end
end

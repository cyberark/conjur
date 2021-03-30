# frozen_string_literal: true

require 'spec_helper'

# These are integration tests that describe the expected client IP address
# behavior for Conjur, considering the entire HTTP server pipeline and how it
# handles the TCP remote IP address, the `TRUSTED_PROXIES` environment variable,
# and the `X-Forwarded-For` HTTP header.
#
# These would generally be better suited as cucumber behavior tests rather than
# RSpec tests. However, in this case we use RSpec for these integration tests for
# two reasons:
#
# 1. Rspec tests are generally faster than Cucumber tests, so if we can test
#    this appropriately in RSpec alone, we can keep the CI execution time lower.
#
# 2. Our cucumber tests currently can't test this as thoroughly as we can in RSpec,
#    because of the way we are able to manipulate the environment and the TCP
#    remote IP with RSpec and the Rails "request" test type. To do this with
#    Cucumber would require greater control of the Docker network and containers
#    for the Conjur cucumber tests than we have now.
RSpec.describe("request IP address determination", type: :request) do
  def request_env(remote_addr)
    {
      # We can't modify the access token middleware to add an exception to our
      # test route, so we need to create an access token for our request to use.
      'HTTP_AUTHORIZATION' => access_token_for('admin'),
      'REMOTE_ADDR' => remote_addr
    }
  end

  def request_ip(remote_addr:, x_forwarded_for: nil, trusted_proxies: nil)
    ENV['TRUSTED_PROXIES'] = trusted_proxies

    headers = {}
    headers['X-Forwarded-For'] = x_forwarded_for if x_forwarded_for
  
    get('/whoami', env: request_env(remote_addr), headers: headers)
  
    JSON.parse(response.body)['client_ip']
  end

  # --------------------------------------------------------------------
  # Test Scenarios
  # --------------------------------------------------------------------

  # Without any other configuration in play, we expect to get the remote
  # TCP connection IP address as the request IP address.
  it 'returns the remote_addr with no additional config' do
    expect(request_ip(remote_addr: '44.0.0.1')).to eq('44.0.0.1')
  end

  it 'ignores the XFF header when the remote addr is untrusted' do
    expect(
      request_ip(
        remote_addr: '44.0.0.1',
        x_forwarded_for: '3.3.3.3'
      )
    ).to eq('44.0.0.1')
    expect(request.remote_ip).to eq('44.0.0.1')
  end

  # `127.0.0.1` is important as the address of the nginx proxy when used in DAP
  it 'trusts the loopback address by default to provide XFF' do
    expect(
      request_ip(
        remote_addr: '127.0.0.1',
        x_forwarded_for: '3.3.3.3'
      )
    ).to eq('3.3.3.3')
    expect(request.remote_ip).to eq('3.3.3.3')
  end

  it 'does not trust other non-routable addresses by default to provide XFF' do
    expect(
      request_ip(
        remote_addr: '192.168.1.1',
        x_forwarded_for: '3.3.3.3'
      )
    ).to eq('192.168.1.1')
    expect(request.remote_ip).to eq('192.168.1.1')
  end

  it "doesn't trust the remote_addr if not included in TRUSTED_PROXIES" do
    expect(
      request_ip(
        remote_addr: '44.0.0.1',
        x_forwarded_for: '3.3.3.3',
        trusted_proxies: '4.4.4.4'
      )
    ).to eq('44.0.0.1')
    expect(request.remote_ip).to eq('44.0.0.1')
  end

  it "trusts 127.0.0.1 for XFF even when not included explicitly with TRUSTED_PROXIES" do
    expect(
      request_ip(
        remote_addr: '127.0.0.1',
        x_forwarded_for: '3.3.3.3',
        trusted_proxies: '4.4.4.4'
      )
    ).to eq('3.3.3.3')
    expect(request.remote_ip).to eq('3.3.3.3')
  end
  
  it "trusts IP ranges for XFF using CIDR notation in TRUSTED_PROXIES" do
    expect(
      request_ip(
        remote_addr: '5.5.5.1',
        x_forwarded_for: '3.3.3.3',
        trusted_proxies: '5.5.5.0/24'
      )
    ).to eq('3.3.3.3')
    expect(request.remote_ip).to eq('3.3.3.3')
  end

  it "returns the expected IP when multiple XFF values are included" do
    expect(
      request_ip(
        remote_addr: '5.5.5.1',
        x_forwarded_for: '3.3.3.3,5.5.5.2,5.5.5.3',
        trusted_proxies: '5.5.5.0/24'
      )
    ).to eq('3.3.3.3')
    expect(request.remote_ip).to eq('3.3.3.3')
  end

  it "returns the expected IP when multiple ranges are included in TRUSTED_PROXIES" do
    expect(
      request_ip(
        remote_addr: '4.4.4.4',
        x_forwarded_for: '3.3.3.3,5.5.5.2,5.5.5.3',
        trusted_proxies: '5.5.5.0/24,4.4.4.0/24'
      )
    ).to eq('3.3.3.3')
    expect(request.remote_ip).to eq('3.3.3.3')
  end

  it "returns the right-most untrusted IP when XFF contains multiple untrusted IPs" do
    expect(
      request_ip(
        remote_addr: '4.4.4.4',
        x_forwarded_for: '3.3.3.3,6.6.6.6,7.7.7.7',
        trusted_proxies: '4.4.4.0/24'
      )
    ).to eq('7.7.7.7')
    expect(request.remote_ip).to eq('7.7.7.7')
  end

  it "returns the right-most untrusted IP when XFF contains some trusted IPs" do
    expect(
      request_ip(
        remote_addr: '4.4.4.4',
        x_forwarded_for: '3.3.3.3,6.6.6.6,5.5.5.5',
        trusted_proxies: '4.4.4.0/24,5.5.5.0/24'
      )
    ).to eq('6.6.6.6')
    expect(request.remote_ip).to eq('6.6.6.6')
  end

  it "returns the right-most untrusted IP when XFF contains a trusted IP in the middle" do
    expect(
      request_ip(
        remote_addr: '4.4.4.4',
        x_forwarded_for: '3.3.3.3,5.5.5.5,6.6.6.6,7.7.7.7',
        trusted_proxies: '4.4.4.0/24,5.5.5.0/24'
      )
    ).to eq('7.7.7.7')
    expect(request.remote_ip).to eq('7.7.7.7')
  end

  it "returns the left-most trusted IP when XFF contains all trusted IPs" do
    expect(
      request_ip(
        remote_addr: '4.4.4.4',
        x_forwarded_for: '5.5.5.5,6.6.6.6',
        trusted_proxies: '4.4.4.4,5.5.5.5,6.6.6.6'
      )
    ).to eq('5.5.5.5')
    expect(request.remote_ip).to eq('5.5.5.5')
  end
end

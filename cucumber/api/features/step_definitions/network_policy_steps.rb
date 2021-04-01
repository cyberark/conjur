When(/^I load a network-restricted policy$/) do
  cuke_network = ENV['CUCUMBER_NETWORK'] || '172.0.0.0/8'
  policy = %Q(
    - !user
      id: alice
      # 192.0.2.0 is an arbitrary subnet that doesn't exist and that
      # doesn't match our actual network to verify that a request origin
      # that doesn't match is unauthorized.
      restricted_to: 192.0.2.0/24

    - !user
      id: bob
      # For positive origin verification, there are two subnets that need
      # to be allowed:
      #
      # 127.0.0.1                   - Allows connections in the local network
      # ENV['CUCUMBER_NETWORK'] - Allows connections in a docker/docker-compose network
      #                               the current network settings
      restricted_to: [ "127.0.0.1", "#{cuke_network}" ]
    ).tap { |p| puts("Network-restricted policy: #{p}") }

  steps %Q(
    When I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    #{policy}
    """
  )
end

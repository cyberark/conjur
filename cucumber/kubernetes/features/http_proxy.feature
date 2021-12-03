Feature: A permitted Conjur host can authenticate with a valid resource restrictions
  that is defined in the id and the kubernetes host can be reached through a
  http_proxy

  @http_proxy
  Scenario: Authenticate as a Pod.
    Given I can login to pod matching "app=inventory-pod" to authn-k8s as "*/*"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "*/*"

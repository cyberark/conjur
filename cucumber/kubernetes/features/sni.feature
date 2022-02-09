Feature: A permitted Conjur host can authenticate with a valid resource restrictions
  that is defined in the id and the kubernetes host has a corresponding SSL certificate

  @sni_fails
  Scenario: Authenticate as a Pod.
    When I authenticate with authn-k8s as "pod/inventory-pod" without cert and key
    Then the HTTP status is "401"

  @sni_success
  Scenario: Authenticate as a Pod.
    Given I can login to pod matching "app=inventory-pod" to authn-k8s as "*/*"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "*/*"

Feature: Errors emitted by the authenticate method.

  # Skip this test as we're not currently doing IP verification.
  @skip
  Scenario: It's an error to authenticate as a different host than the one that sent the request.
    Given I login to authn-k8s as "stateful_set/inventory-stateful"
    And I use the IP address of a pod in "pod/inventory-pod"
    When I authenticate with authn-k8s as "stateful_set/inventory-stateful"
    Then the HTTP status is "401"

  Scenario: It's an error to authenticate as a host which does not hold "authenticate" privilege 
    on the webservice.
    When I authenticate with authn-k8s as "pod/inventory-unauthorized" without cert and key
    Then the HTTP status is "401"

  Scenario: It's an error to authenticate without providing a cert and key.
    When I authenticate with authn-k8s as "pod/inventory-pod" without cert and key
    Then the HTTP status is "401"

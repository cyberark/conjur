@authenticators_k8s
Feature: Errors emitted by the authenticate method.

  @negative @acceptance
  Scenario: it raises an error when authenticating as a host which does not hold "authenticate" privilege
    on the webservice.
    When I authenticate with authn-k8s as "pod/inventory-unauthorized" without cert and key
    Then the HTTP status is "403"

  @negative @acceptance
  Scenario: it raises an error when authenticating without providing a cert and key.
    When I authenticate with authn-k8s as "pod/inventory-pod" without cert and key
    Then the HTTP status is "401"

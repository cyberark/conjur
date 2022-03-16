@authenticators_k8s
Feature: Errors emitted by the login method.

  @negative @acceptance
  Scenario: Login for unsupported resource type identity scope throws an AuthenticationError .
    Given I login to pod matching "app=inventory-deployment" to authn-k8s as "node/inventory-node"
    Then the HTTP status is "401"

  # Skip this test as we're not currently doing IP verification.
  @skip
  @negative @acceptance
  Scenario: it raises an error when logging in as a different host than the one that sent the request.
    Given I login to authn-k8s as "stateful_set/inventory-stateful"
    And I use the IP address of "pod/inventory-pod"
    When I login to authn-k8s as "stateful_set/inventory-stateful"
    Then the HTTP status is "401"

  @negative @acceptance
  Scenario: it raises an error when logging in as a host which does not hold "authenticate" privilege
    on the webservice.
    When I login to authn-k8s as "pod/inventory-unauthorized"
    Then the HTTP status is "403"

  @negative @acceptance
  Scenario: it raises an error when logging in with a custom prefix as a host which does not
    hold "authenticate" privilege on the webservice.
    When I login to authn-k8s as "@namespace@/pod/inventory-unauthorized" with prefix "host/conjur/authn-k8s/minikube/apps"
    Then the HTTP status is "403"

  @negative @acceptance
  Scenario: it raises an error when logging in with a service account which does not match the calling pod.
    When I login to pod matching "app=inventory-deployment" to authn-k8s as "service_account/inventory-pod-only"
    Then the HTTP status is "401"

  @negative @acceptance
  Scenario: it raises an error when logging in from a namespace which does not match the one configured in the host.
    When I login to pod matching "app=inventory-deployment" to authn-k8s as "incorrect-namespace/*/*" with prefix "host/conjur/authn-k8s/minikube/apps"
    Then the HTTP status is "401"

  @acceptance
  Scenario: Cert injection errors are written to a file in the client container
    When I login to pod matching "app=inventory-no-ssl-dir" to authn-k8s as "*/*"
    Then the cert injection logs exist in the client container

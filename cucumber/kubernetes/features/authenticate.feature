@authenticators_k8s
Feature: A permitted Conjur host can authenticate with a valid resource restrictions
  that is defined in the id

  @smoke
  Scenario: Authenticate as a Pod.
    Given I login to authn-k8s as "pod/inventory-pod"
    Then I can authenticate with authn-k8s as "pod/inventory-pod"

  @smoke
  Scenario: Authenticate as a Namespace.
    Given I can login to pod matching "app=inventory-pod" to authn-k8s as "*/*"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "*/*"

  @smoke
  Scenario: Authenticate as a ServiceAccount.
    Given I can login to pod matching "app=inventory-pod" to authn-k8s as "service_account/inventory-pod-only"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "service_account/inventory-pod-only"

  @smoke
  Scenario: Authenticate as a Deployment.
    Given I login to authn-k8s as "deployment/inventory-deployment"
    Then I can authenticate with authn-k8s as "deployment/inventory-deployment"

  @smoke
  Scenario: Authenticate as a StatefulSet.
    Given I login to authn-k8s as "stateful_set/inventory-stateful"
    Then I can authenticate with authn-k8s as "stateful_set/inventory-stateful"

  @acceptance
  Scenario: Authenticate using a certificate signed by a different CA
    Then I cannot authenticate with pod matching "pod/inventory-pod" as "service_account/inventory-pod-only" using a cert signed by a different CA

  @acceptance
  Scenario: Authenticate as a host defined under the root policy
    Given I login to pod matching "app=inventory-pod" to authn-k8s as "@namespace@/*/*" with prefix "host"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "@namespace@/*/*" with prefix "host"

  @acceptance
  Scenario: Authenticate without the "authentication-container-name" annotation defaults to "authenticator" and succeeds
    Given I login to pod matching "app=inventory-pod" to authn-k8s as "@namespace@/*/*" with prefix "host/host-without-container-name"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "@namespace@/*/*" with prefix "host/host-without-container-name"

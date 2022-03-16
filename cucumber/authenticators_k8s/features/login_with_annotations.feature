@authenticators_k8s
Feature: A permitted Conjur host can login with a valid resource restrictions
  that is defined in annotations

  @smoke
  Scenario: Login as the namespace a pod belongs to.
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-namespace" with prefix "host/some-policy"

  @negative @acceptance
  Scenario: Login for unsupported resource type identity scope throws an AuthenticationError .
    Given I login to pod matching "app=inventory-deployment" to authn-k8s as "test-app-non-permited-scope" with prefix "host/some-policy"
    Then the HTTP status is "401"

  @smoke
  Scenario: Login as a Pod.
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-pod" with prefix "host/some-policy"

  @smoke
  Scenario: Login as a ServiceAccount.
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-service-account" with prefix "host/some-policy"

  @k8s_skip
  @smoke
  Scenario: Login as a DeploymentConfig.
    Then I can login to pod matching "app=inventory-deployment-cfg" to authn-k8s as "test-app-deployment-config" with prefix "host/some-policy"

  @smoke
  Scenario: Login as a Deployment.
    Then I can login to pod matching "app=inventory-deployment" to authn-k8s as "test-app-deployment" with prefix "host/some-policy"

  @smoke
  Scenario: Login as a StatefulSet.
    Then I can login to pod matching "app=inventory-stateful" to authn-k8s as "test-app-stateful-set" with prefix "host/some-policy"

  @acceptance
  Scenario: Login as a Pod and a ServiceAccount
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-multiple-constraints" with prefix "host/some-policy"

  @acceptance
  Scenario: Login as the namespace a pod belongs to when the constraint is on the authenticator.
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-service-id-constraint" with prefix "host/some-policy"

  @acceptance
  Scenario: Login as the namespace a pod belongs to when a constraint defined twice: on the authenticator and granular.
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-service-id-and-general-constraint" with prefix "host/some-policy"

  @acceptance
  Scenario: Login with a host defined in the root policy
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "root-based-app" with prefix "host"

  @negative @acceptance
  Scenario: it raises an error when logging in with a host that has an unsupported resource type
    Given I login to pod matching "app=inventory-deployment" to authn-k8s as "test-app-non-permited-scope" with prefix "host/some-policy"
    Then the HTTP status is "401"

  @negative @acceptance
  Scenario: it raises an error when logging in from a namespace which does not match the one configured in the host
    When I login to pod matching "app=inventory-deployment" to authn-k8s as "test-app-incorrect-namespace" with prefix "host/some-policy"
    Then the HTTP status is "401"

  @negative @acceptance
  Scenario: it raises an error when logging in with a non-existing K8s resource
    When I login to pod matching "app=inventory-pod" to authn-k8s as "test-app-non-existing-resource" with prefix "host/some-policy"
    Then the HTTP status is "401"

  @negative @acceptance
  Scenario: it raises an error when logging in from a K8s resource which does not match the one configured in the host
    When I login to pod matching "app=inventory-pod" to authn-k8s as "test-app-incorrect-resource" with prefix "host/some-policy"
    Then the HTTP status is "401"

  @acceptance
  Scenario: Login without the "authentication-container-name" annotation defaults to "authenticator" and succeeds
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-no-container-annotation" with prefix "host/some-policy"

  @acceptance
  Scenario: Login with "kubernetes/authentication-container-name" annotation and succeeds
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-kubernetes-container-annotation" with prefix "host/some-policy"

  @negative @acceptance
  Scenario: It raises an error when logging in from a container which does not match the one configured in the host
    When I login to pod matching "app=inventory-pod" to authn-k8s as "test-app-incorrect-container-annotation" with prefix "host/some-policy"
    Then the HTTP status is "401"

  @acceptance
  Scenario: Login when the "authentication-container-name" annotation defined twice: on the authenticator and granular.
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-service-id-and-granular-container-annotation" with prefix "host/some-policy"

  @acceptance
  Scenario: Login when the "authentication-container-name" annotation defined twice: granular and with 'kubernetes' prefix.
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-authn-and-kubernetes-container-annotation" with prefix "host/some-policy"

  @negative @acceptance
  Scenario: It raises an error when logging in from a container which does not match the one configured in the host for the service-id, although it is configured correctly for both granular and with 'kubernetes' prefix.
    When I login to pod matching "app=inventory-pod" to authn-k8s as "test-app-incorrect-service-id-container-annotation" with prefix "host/some-policy"
    Then the HTTP status is "401"

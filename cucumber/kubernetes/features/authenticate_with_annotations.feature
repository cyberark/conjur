@authenticators_k8s
Feature: A permitted Conjur host can login with a valid resource restrictions
  that is defined in annotations

  @smoke
  Scenario: Authenticate as a Pod.
    Given I login to pod matching "app=inventory-pod" to authn-k8s as "test-app-pod" with prefix "host/some-policy"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "test-app-pod" with prefix "host/some-policy"

  @acceptance
  Scenario: Authenticate as a Pod with long host prefix.
    Given I login to pod matching "app=inventory-pod" to authn-k8s as "test-app-pod" with prefix "host/some-policy/second-layer"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "test-app-pod" with prefix "host/some-policy/second-layer"

  @acceptance
  Scenario: Authenticate as a Pod with medium host prefix.
    Given I login to pod matching "app=inventory-pod" to authn-k8s as "second-layer/test-app-pod" with prefix "host/some-policy"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "second-layer/test-app-pod" with prefix "host/some-policy"

  @acceptance
  Scenario: Authenticate as a Pod with short host prefix.
    Given I login to pod matching "app=inventory-pod" to authn-k8s as "some-policy/second-layer/test-app-pod" with prefix "host"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "some-policy/second-layer/test-app-pod" with prefix "host"

  @smoke
  Scenario: Authenticate as a Namespace.
    Given I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-namespace" with prefix "host/some-policy"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "test-app-namespace" with prefix "host/some-policy"

  @smoke
  Scenario: Authenticate as a ServiceAccount.
    Given I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-service-account" with prefix "host/some-policy"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "test-app-service-account" with prefix "host/some-policy"

  @smoke
  Scenario: Authenticate as a Deployment.
    Given I can login to pod matching "app=inventory-deployment" to authn-k8s as "test-app-deployment" with prefix "host/some-policy"
    Then I can authenticate pod matching "pod/inventory-deployment" with authn-k8s as "test-app-deployment" with prefix "host/some-policy"

  @smoke
  Scenario: Authenticate as a StatefulSet.
    Given I can login to pod matching "app=inventory-stateful" to authn-k8s as "test-app-stateful-set" with prefix "host/some-policy"
    Then I can authenticate pod matching "pod/inventory-stateful" with authn-k8s as "test-app-stateful-set" with prefix "host/some-policy"

  @k8s_skip
  @smoke
  Scenario: Authenticate as a DeploymentConfig.
    Given I can login to pod matching "app=inventory-deployment-cfg" to authn-k8s as "test-app-deployment-config" with prefix "host/some-policy"
    Then I can authenticate pod matching "pod/inventory-deployment-cfg" with authn-k8s as "test-app-deployment-config" with prefix "host/some-policy"

  @acceptance
  Scenario: Authenticate as a host defined under the root policy
    Given I login to pod matching "app=inventory-pod" to authn-k8s as "root-based-app" with prefix "host"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "root-based-app" with prefix "host"

  @acceptance
  Scenario: Authenticate without the "authentication-container-name" annotation defaults to "authenticator" and succeeds
    Given I can login to pod matching "app=inventory-pod" to authn-k8s as "test-app-no-container-annotation" with prefix "host/some-policy"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "test-app-no-container-annotation" with prefix "host/some-policy"

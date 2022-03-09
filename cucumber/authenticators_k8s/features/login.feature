@authenticators_k8s
Feature: A permitted Conjur host can login with a valid resource restrictions
  that is defined in the id

  @smoke
  Scenario: Login as the namespace a pod belongs to.
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "*/*"

  @smoke
  Scenario: Login as a Pod.
    Then I can login to authn-k8s as "pod/inventory-pod"

  @smoke
  Scenario: Login as a ServiceAccount.
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "service_account/inventory-pod-only"

  @k8s_skip
  @smoke
  Scenario: Login as a DeploymentConfig.
    Then I can login to pod matching "app=inventory-deployment-cfg" to authn-k8s as "deployment_config/inventory-deployment-cfg"

  @smoke
  Scenario: Login as a Deployment.
    Then I can login to authn-k8s as "deployment/inventory-deployment"

  @smoke
  Scenario: Login as a StatefulSet.
    Then I can login to authn-k8s as "stateful_set/inventory-stateful"

  @acceptance
  Scenario: Login with a custom prefix.
    Then I can login to authn-k8s as "@namespace@/pod/inventory-pod" with prefix "host/some-policy"

  @acceptance
  Scenario: Login with a host defined in the root policy
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "@namespace@/*/*" with prefix "host"

  @acceptance
  Scenario: Login without the "authentication-container-name" annotation defaults to "authenticator" and succeeds
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "@namespace@/*/*" with prefix "host/host-without-container-name"

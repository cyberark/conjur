Feature: An authorized client can login as a permitted role

  Scenario: Login as the namespace a pod belongs to.
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "*/*"

  Scenario: Login for unsupported resource type identity scope throws an AuthenticationError .
    Given I login to pod matching "app=inventory-deployment" to authn-k8s as "node/inventory-node"
    Then the HTTP status is "401"

  Scenario: Login as a Pod.
    Then I can login to authn-k8s as "pod/inventory-pod"

  Scenario: Login as a ServiceAccount.
    Then I can login to pod matching "app=inventory-pod" to authn-k8s as "service_account/inventory-pod-only"

  @k8s_skip
  Scenario: Login as a DeploymentConfig.
    Then I can login to pod matching "app=inventory-deployment-cfg" to authn-k8s as "deployment_config/inventory-deployment-cfg"

  Scenario: Login as a Deployment.
    Then I can login to authn-k8s as "deployment/inventory-deployment"

  Scenario: Login as a StatefulSet.
    Then I can login to authn-k8s as "stateful_set/inventory-stateful"

  Scenario: Login with a custom prefix.
    Then I can login to authn-k8s as "@namespace@/pod/inventory-pod" with prefix "host/some-policy"

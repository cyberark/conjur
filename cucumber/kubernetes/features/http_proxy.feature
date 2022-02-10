Feature: A permitted Conjur host can authenticate with a valid resource restrictions
  that is defined in the id and the kubernetes host can be reached through a
  http_proxy

  #  This test executes an authentication against k8s through an http proxy
  #  and is executed after standing up the
  #  ci/authn-k8s/dev/dev_conjur_http_proxy.template.yaml file in the k8s
  #  environment to ensure the proxy and env variable are available
  @http_proxy
  Scenario: Authenticate as a Pod.
    Given I can login to pod matching "app=inventory-pod" to authn-k8s as "*/*"
    Then I can authenticate pod matching "pod/inventory-pod" with authn-k8s as "*/*"

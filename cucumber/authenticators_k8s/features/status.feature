@authenticators_k8s
Feature: Kubernetes Authenticator - Status Check

  @smoke
  Scenario: A properly configured Kubernetes authenticator returns a successful response
    # The policy for the status endpoint is loaded when this test environment
    # is initially configured in k8s.
    When I GET "/authn-k8s/minikube/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

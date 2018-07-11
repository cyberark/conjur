Feature: Certificates issued by the login method.

  Scenario: The subject name is the dot-separated relative Conjur host ID.
    When I can login to pod matching "app=inventory-pod" to authn-k8s as "*/*"
    Then the certificate subject name is "/CN=@namespace@.*.*"

  Scenario: The TTL of the certificate is 3 days.
    When I can login to pod matching "app=inventory-pod" to authn-k8s as "*/*"
    Then the certificate is valid for 3 days

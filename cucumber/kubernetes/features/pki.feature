@authenticators_k8s
Feature: Certificates issued by the login method.

  @acceptance
  Scenario: The subject name is the dot-separated, with hard-coded apps prefix, Conjur host ID when the "Host-Id-Prefix" header isn't present.
    When I can login to pod matching "app=inventory-pod" to authn-k8s as "*/*"
    Then the certificate subject name is "/CN=host.conjur.authn-k8s.minikube.apps.@namespace@.*.*"

  @acceptance
  Scenario: The subject name is the dot-separated given Conjur host ID in apps when the "Host-Id-Prefix" header is present
    When I can login to pod matching "app=inventory-pod" to authn-k8s as "@namespace@/*/*" with prefix "host/conjur/authn-k8s/minikube/apps"
    Then the certificate subject name is "/CN=host.conjur.authn-k8s.minikube.apps.@namespace@.*.*"

  @acceptance
  Scenario: The subject name is the dot-separated given Conjur host ID outside of apps when the "Host-Id-Prefix" header is present
    When I can login to pod matching "app=inventory-pod" to authn-k8s as "@namespace@/*/*" with prefix "host/some-policy"
    Then the certificate subject name is "/CN=host.some-policy.@namespace@.*.*"

  @acceptance
  Scenario: The TTL of the certificate is 3 days.
    When I can login to pod matching "app=inventory-pod" to authn-k8s as "*/*"
    Then the certificate is valid for 3 days

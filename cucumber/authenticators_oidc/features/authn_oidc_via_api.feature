@authenticators_oidc
Feature: OIDC Authenticator created via API

  Background:
    Given the following environment variables are available:
      | context_variable            | environment_variable   | default_value                                                    |
      | oidc_provider_internal_uri  | PROVIDER_INTERNAL_URI  | http://keycloak:8080/auth/realms/master/protocol/openid-connect  |
      | oidc_scope                  | KEYCLOAK_SCOPE         | openid                                                           |
      | oidc_client_id              | KEYCLOAK_CLIENT_ID     | conjurClient                                                     |
      | oidc_client_secret          | KEYCLOAK_CLIENT_SECRET | 1234                                                             |
      | oidc_ca_cert                | KEYCLOAK_CA_CERT       |                                                                  |
    When I load a policy:
    """
    - !policy conjur/authn-oidc
    """
    Given I successfully initialize an OIDC authenticator named "keycloak" via the authenticators API
    When I extend the policy with:
    """
    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/apps
      member: !user alice
    """

  @acceptance
  Scenario: Authenticator is configured properly
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the audit log file

    When I authenticate via OIDC with id token in header
    Then user "alice" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:alice successfully authenticated with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak
    """

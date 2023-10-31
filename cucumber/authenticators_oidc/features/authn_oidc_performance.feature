@authenticators_oidc
Feature: OIDC Authenticator - Performance tests

  In this feature we test that OIDC Authenticator performance is meeting
  the SLA. We run multiple authn-oidc requests in multiple threads and verify
  that the average time of a request is no more that the agreed time.
  We test both successful requests and unsuccessful requests.

  Background:
    Given the following environment variables are available:
      | context_variable            | environment_variable   | default_value                            |
      | oidc_provider_internal_uri  | PROVIDER_INTERNAL_URI  | http://keycloak:8080/auth/realms/master/protocol/openid-connect |
      | oidc_scope                  | KEYCLOAK_SCOPE         | openid                                                          |
      | oidc_client_id              | KEYCLOAK_CLIENT_ID     | conjurClient                                                    |
      | oidc_client_secret          | KEYCLOAK_CLIENT_SECRET | 1234                                                            |
      | oidc_provider_uri           | PROVIDER_URI           | https://keycloak:8443/auth/realms/master                        |
      | oidc_id_token_user_property | ID_TOKEN_USER_PROPERTY | preferred_username                                              |
      | oidc_ca_cert                | KEYCLOAK_CA_CERT       |                                                                 |

    And I load a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !variable
        id: provider-uri

      - !variable
        id: id-token-user-property

      - !variable
        id: ca-cert

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice
    """
    And I set the following conjur variables:
      | variable_id                                       | context_variable            |
      | conjur/authn-oidc/keycloak/id-token-user-property | oidc_id_token_user_property |
      | conjur/authn-oidc/keycloak/provider-uri           | oidc_provider_uri           |
      | conjur/authn-oidc/keycloak/ca-cert                | oidc_ca_cert                |

  @performance
  Scenario: successful requests
    And I fetch an ID Token for username "alice" and password "alice"
    When I authenticate 1000 times in 10 threads via OIDC with id token
    Then The avg authentication request responds in less than 0.75 seconds

  @performance
  Scenario: Unsuccessful requests with an invalid token
    When I authenticate 1000 times in 10 threads via OIDC with invalid id token
    Then The avg authentication request responds in less than 0.75 seconds

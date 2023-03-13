@authenticators_oidc
Feature: OIDC Authenticator - Bad authenticator configuration leads to an error

  In this feature we define an OIDC Authenticator with a configuration
  mistake. Each test will verify that we fail the authentication in such a case
  and log the relevant error for the user to re-configure the authenticator
  properly

  Background:
    Given the following environment variables are available:
      | context_variable            | environment_variable    | default_value                                                   |
      | oidc_provider_internal_uri  | PROVIDER_INTERNAL_URI   | http://keycloak:8080/auth/realms/master/protocol/openid-connect |
      | oidc_scope                  | KEYCLOAK_SCOPE          | openid                                                          |
      | oidc_client_id              | KEYCLOAK_CLIENT_ID      | conjurClient                                                    |
      | oidc_client_secret          | KEYCLOAK_CLIENT_SECRET  | 1234                                                            |
      | oidc_provider_uri           | PROVIDER_URI            | https://keycloak:8443/auth/realms/master                        |
      | oidc_id_token_user_property | ID_TOKEN_USER_PROPERTY  | preferred_username                                              |

  @negative @acceptance
  Scenario: id-token-user-property variable missing in policy is denied
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !variable
        id: provider-uri

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
      | variable_id                             | context_variable  |
      | conjur/authn-oidc/keycloak/provider-uri | oidc_provider_uri |
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Conjur::RequiredResourceMissing
    """

  @negative @acceptance
  Scenario: provider-uri variable missing in policy is denied
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !variable
        id: id-token-user-property

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
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Conjur::RequiredResourceMissing
    """

  @negative @acceptance
  Scenario: webservice missing in policy is denied
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:

      - !variable
        id: provider-uri

      - !variable
        id: id-token-user-property

      - !group users

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice
    """
    And I set the following conjur variables:
      | variable_id                                       | context_variable            |
      | conjur/authn-oidc/keycloak/id-token-user-property | oidc_id_token_user_property |
      | conjur/authn-oidc/keycloak/provider-uri           | oidc_provider_uri           |
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::WebserviceNotFound
    """

  @negative @acceptance
  Scenario: webservice with read and no authenticate permission in policy is denied
    Given I load a policy:
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

        - !group users

        - !permit
          role: !group users
          privilege: [ read ]
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
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is forbidden
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotAuthorizedOnResource
    """

  @negative @acceptance
  Scenario: An authenticator without a service id
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-oidc
      body:
      - !webservice

      - !variable
        id: provider-uri

      - !variable
        id: id-token-user-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/users
      member: !user alice
    """
    And I set the following conjur variables:
      | variable_id                               | context_variable            |
      | conjur/authn-oidc/id-token-user-property  | oidc_id_token_user_property |
      | conjur/authn-oidc/provider-uri            | oidc_provider_uri           |
    Given I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    When I authenticate via OIDC with id token and without a service-id
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AuthnOidc::ServiceIdMissing
    """

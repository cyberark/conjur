Feature: initialize an authenticator through the api

  Background:
    Given I login as "admin"

  @smoke @acceptance
  Scenario: I initialize a k8s authenticator with name test-service
    When I save my place in the audit log file for remote
    And I POST "/authn-k8s/test-service/cucumber"
    Then the HTTP response status code is 201
    And the HTTP response content type is "text/yaml"
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-k8s/test-service
      body:
      - !webservice
      - !policy
        id: ca
        body:
        - !variable cert
        - !variable key

      - !policy
        id: kubernetes
        body:
        - !variable service-account-token
        - !variable ca-cert
        - !variable api-url

      - !layer users

      - !permit
        resource: !webservice
        privilege: [ read, authenticate ]
        role: !layer users

    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:policy:conjur/authn-k8s/test-service"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:root" version="1"]
      cucumber:user:admin added role cucumber:policy:conjur/authn-k8s/test-service
    """

  Scenario: I initialize a pre-existing k8s authenticator
    When I POST "/authn-k8s/test-service/cucumber"
    And I POST "/authn-k8s/test-service/cucumber"
    Then the HTTP response status code is 200
    And the HTTP response content type is "text/yaml"
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-k8s/test-service
      body:
      - !webservice
      - !policy
        id: ca
        body:
        - !variable cert
        - !variable key

      - !policy
        id: kubernetes
        body:
        - !variable service-account-token
        - !variable ca-cert
        - !variable api-url

      - !layer users

      - !permit
        resource: !webservice
        privilege: [ read, authenticate ]
        role: !layer users

      """

  @negative @acceptance
  Scenario: I initialize a k8s authenticator with extra body parameters
    When I POST "/authn-k8s/test-service/cucumber" with body:
    """
    {
      "extra-param": "value"
    }
    """
    Then the HTTP response status code is 422

  Scenario: I initialize a pre-existing Azure authenticator
    When I POST "/authn-azure/test-azure-service/cucumber" with body:
    """
    {
      "provider-uri": "http://fake-url.com"
    }
    """
    And I POST "/authn-azure/test-azure-service/cucumber" with body:
    """
    {
      "provider-uri": "http://fake-url2.com"
    }
    """
    Then the HTTP response status code is 200
    And the HTTP response content type is "text/yaml"
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-azure/test-azure-service
      body:
      - !webservice

      - !variable provider-uri

      - !layer users

      - !permit
        resource: !webservice
        privilege: [ read, authenticate ]
        role: !layer users

    """

  @negative
  Scenario: I initialize an Azure authenticator with extra body parameters
    When I POST "/authn-azure/test-azure-service/cucumber" with body:
    """
    {
      "provider-uri": "http://fake-url.com",
      "extra-param": "value
    }
    """
    Then the HTTP response status code is 422

  @smoke @acceptance
  Scenario: I initialize an OIDC authenticator with name test-oidc-service
    When I save my place in the audit log file for remote
    And I POST "/authn-oidc/test-oidc-service/cucumber" with body:
    """
    {
      "provider-uri": "http://fake-url.com",
      "id-token-user-property": "fake-user"
    }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is "text/yaml"
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-oidc/test-oidc-service
      body:
      - !webservice

      - !variable provider-uri
      - !variable id-token-user-property

      - !layer users

      - !permit
        resource: !webservice
        privilege: [ read, authenticate ]
        role: !layer users

    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:policy:conjur/authn-oidc/test-oidc-service"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:root" version="1"]
      cucumber:user:admin added role cucumber:policy:conjur/authn-oidc/test-oidc-service
    """

  Scenario: I initialize a pre-existing OIDC authenticator
    When I POST "/authn-oidc/test-oidc-service/cucumber" with body:
    """
    {
      "provider-uri": "http://fake-url.com",
      "id-token-user-property": "fake-user"
    }
    """
    And I POST "/authn-oidc/test-oidc-service/cucumber" with body:
    """
    {
      "provider-uri": "http://fake-url.com",
      "id-token-user-property": "fake-user"
    }
    """
    Then the HTTP response status code is 200
    And the HTTP response content type is "text/yaml"
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-oidc/test-oidc-service
      body:
      - !webservice

      - !variable provider-uri
      - !variable id-token-user-property

      - !layer users

      - !permit
        resource: !webservice
        privilege: [ read, authenticate ]
        role: !layer users

    """

  @negative
  Scenario: I initialize an OIDC authenticator with extra body parameters
    When I POST "/authn-oidc/test-oidc-service/cucumber" with body:
    """
    {
      "provider-uri": "http://fake-url.com",
      "id-token-user-property": "fake-user"
      "extra-param": "value
    }
    """
    Then the HTTP response status code is 422

  @negative @acceptance
  Scenario: I attempt to initialize an authenticator as an unauthorized user
    When I create a new user "alice"
    And I login as "alice"
    And I POST "/authn-k8s/test/cucumber"
    Then the HTTP response status code is 403

  @negative
  Scenario: I attempt to initialize an authenticator with bad request body
    When I POST "/authn-oidc/test-oidc-service/cucumber" with body:
    """
    {
      bad-json-syntax
    }
    """
    Then the HTTP response status code is 422

  @smoke @acceptance
  Scenario: I initialize an GCP authenticator
    When I save my place in the audit log file for remote
    And I POST "/authn-gcp/cucumber"
    Then the HTTP response status code is 201
    And the HTTP response content type is "text/yaml"
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-gcp/authenticator
      body:
      - !webservice

      - !layer users

      - !permit
        resource: !webservice
        privilege: [ read, authenticate ]
        role: !layer users

    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:policy:conjur/authn-gcp/authenticator"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:root" version="1"]
      cucumber:user:admin added role cucumber:policy:conjur/authn-gcp/authenticator
    """

  Scenario: I initialize a pre-existing GCP authenticator
    When I POST "/authn-gcp/cucumber"
    And I POST "/authn-gcp/cucumber"
    Then the HTTP response status code is 200
    And the HTTP response content type is "text/yaml"
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-gcp/authenticator
      body:
      - !webservice

      - !layer users

      - !permit
        resource: !webservice
        privilege: [ read, authenticate ]
        role: !layer users

    """

  @negative
  Scenario: I initialize an GCP authenticator with extra params
    When I POST "/authn-gcp/cucumber" with body:
    """
    {
      "extra-param": "value"
    }
    """
    Then the HTTP response status code is 422

  @smoke @acceptance
  Scenario: I initialize an IAM authenticator
    When I save my place in the audit log file for remote
    And I POST "/authn-iam/test-service/cucumber"
    Then the HTTP response status code is 201
    And the HTTP response content type is "text/yaml"
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-iam/test-service
      body:
      - !webservice

      - !layer users

      - !permit
        resource: !webservice
        privilege: [ read, authenticate ]
        role: !layer users

    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:policy:conjur/authn-iam/test-service"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:root" version="1"]
      cucumber:user:admin added role cucumber:policy:conjur/authn-iam/test-service
    """

  Scenario: I initialize a pre-existing IAM authenticator
    When I POST "/authn-iam/test-service/cucumber"
    And I POST "/authn-iam/test-service/cucumber"
    Then the HTTP response status code is 200
    And the HTTP response content type is "text/yaml"
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-iam/test-service
      body:
      - !webservice

      - !layer users

      - !permit
        resource: !webservice
        privilege: [ read, authenticate ]
        role: !layer users

    """

  @negative
  Scenario: I initialize an IAM authenticator with extra params
    When I POST "/authn-iam/test-iam-service/cucumber" with body:
    """
    {
      "extra-param": "value"
    }
    """
    Then the HTTP response status code is 422

  @smoke @acceptance
  Scenario: I initialize an LDAP authenticator
    When I save my place in the audit log file for remote
    And I POST "/authn-ldap/cucumber" with body:
    """
    {
      "bind-password": "super-secret",
      "tls-ca-cert": "-BEGIN CERTIFICATE-\nstuf\n-END CERTIFICATE-",
      "annotations": {
        "some": "values"
      }
    }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is "text/yaml"
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-ldap/authenticator
      body:
      - !webservice
        annotations:
          some: values

      - !variable bind-password
      - !variable tls-ca-cert

      - !layer users

      - !permit
        resource: !webservice
        privilege: [ read, authenticate ]
        role: !layer users

    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:policy:conjur/authn-ldap/authenticator"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:root" version="1"]
      cucumber:user:admin added role cucumber:policy:conjur/authn-ldap/authenticator
    """
  
  Scenario: I initialize a pre-existing LDAP authenticator
    When I POST "/authn-ldap/cucumber" with body:
    """
    {
      "bind-password": "super-secret",
      "tls-ca-cert": "-BEGIN CERTIFICATE-\nstuf\n-END CERTIFICATE-",
      "annotations": {
        "some": "values"
      }
    }
    """
    And I POST "/authn-ldap/cucumber" with body:
    """
    {
      "bind-password": "super-secret",
      "tls-ca-cert": "-BEGIN CERTIFICATE-\nstuf\n-END CERTIFICATE-",
      "annotations": {
        "some": "values"
      }
    }
    """
    Then the HTTP response status code is 200
    And the HTTP response content type is "text/yaml"
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-ldap/authenticator
      body:
      - !webservice
        annotations:
          some: values

      - !variable bind-password
      - !variable tls-ca-cert

      - !layer users

      - !permit
        resource: !webservice
        privilege: [ read, authenticate ]
        role: !layer users

    """

  @negative
  Scenario: I initialize an LDAP authenticator with extra params
    When I POST "/authn-ldap/cucumber" with body:
    """
    {
      "bind-password": "super-secret",
      "tls-ca-cert": "-BEGIN CERTIFICATE-\nstuf\n-END CERTIFICATE-",
      "annotations": {
        "some": "values"
      },
      "extra-param": "value"
    }
    """
    Then the HTTP response status code is 422

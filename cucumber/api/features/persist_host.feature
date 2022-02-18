Feature: Persist a authenticator host through the api

  Background:
    Given I login as "admin"

  @smoke
  Scenario: I initialize an K8s authenticator host with name test-host
    When I persist an "authn-k8s" authenticator with service id "test-service"
    And I save my place in the audit log file for remote
    And I POST "/authn-k8s/test-service/cucumber/host" with body:
    """
    {
      "id": "test-host",
      "annotations": {
        "authn-k8s/namespace": "test-namespace"
      }
    }
    """
    Then the HTTP response status code is 201
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-k8s/test-service/apps
      body:
      - !host
        id: test-host
        annotations:
          authn-k8s/namespace: test-namespace

    - !grant
     role: !layer conjur/authn-k8s/test-service/users
     members:
       - !host conjur/authn-k8s/test-service/apps/test-host

    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:host:conjur/authn-k8s/test-service/apps/test-host"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="change"]
      [policy@43868 id="cucumber:policy:root" version="*"]
      cucumber:user:admin changed role cucumber:host:conjur/authn-k8s/test-service/apps/test-host
    """

  @acceptance @smoke
  Scenario: I initialize an K8s authenticator host with extra annotations
    When I persist an "authn-k8s" authenticator with service id "test-service"
    And I POST "/authn-k8s/test-service/cucumber/host" with body:
    """
    {
      "id": "test-host",
      "annotations": {
        "authn-k8s/namespace": "test-namespace",
        "extra-annotation": "extra annotation details"
      }
    }
    """
    Then the HTTP response status code is 201
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-k8s/test-service/apps
      body:
      - !host
        id: test-host
        annotations:
          authn-k8s/namespace: test-namespace
          extra-annotation: extra annotation details

    - !grant
     role: !layer conjur/authn-k8s/test-service/users
     members:
       - !host conjur/authn-k8s/test-service/apps/test-host

    """

  @negative @acceptance
  Scenario: I initialize an K8s authenticator host with missing annotations
    When I persist an "authn-k8s" authenticator with service id "test-service"
    And I POST "/authn-k8s/test-service/cucumber/host" with body:
    """
    {
      "id": "test-host"
    }
    """
    Then the HTTP response status code is 422


  @negative @acceptance
  Scenario: I initialize an K8s authenticator host with extra auth annotations
    When I persist an "authn-k8s" authenticator with service id "test-service"
    And I POST "/authn-k8s/test-service/cucumber/host" with body:
    """
    {
      "id": "test-host",
      "annotations": {
        "authn-k8s/namespace": "test-namespace",
        "authn-k8s/bad-param": "bad parameter"
      }
    }
    """
    Then the HTTP response status code is 422

  @smoke @acceptance
  Scenario: I initialize an Azure authenticator host with name test-host
    When I persist an "authn-azure" authenticator with service id "test-service" and JSON:
    """
    {
      "provider-uri": "https://some-provider"
    }
    """
    And I save my place in the audit log file for remote
    And I POST "/authn-azure/test-service/cucumber/host" with body:
    """
    {
      "id": "test-host",
      "annotations": {
        "authn-azure/subscription-id": "sub id",
        "authn-azure/resource-group": "res group"
      }
    }
    """
    Then the HTTP response status code is 201
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-azure/test-service/apps
      body:
      - !host
        id: test-host
        annotations:
          authn-azure/subscription-id: sub id
          authn-azure/resource-group: res group

    - !grant
     role: !layer conjur/authn-azure/test-service/users
     members:
       - !host conjur/authn-azure/test-service/apps/test-host

    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:host:conjur/authn-azure/test-service/apps/test-host"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="change"]
      [policy@43868 id="cucumber:policy:root" version="*"]
      cucumber:user:admin changed role cucumber:host:conjur/authn-azure/test-service/apps/test-host
    """

  @negative @acceptance
  Scenario: I initialize an Azure authenticator host with extra auth annotations
    When I persist an "authn-azure" authenticator with service id "test-service" and JSON:
    """
    {
      "provider-uri": "https://some-provider"
    }
    """
    And I POST "/authn-azure/test-service/cucumber/host" with body:
    """
    {
      "id": "test-host",
      "annotations": {
        "authn-azure/subscription-id": "sub id",
        "authn-azure/resource-group": "res group",
        "authn-azure/extra-param": "extra"
      }
    }
    """
    Then the HTTP response status code is 422

  @negative @acceptance
  Scenario: I initialize an Azure authenticator host with missing annotations
    When I persist an "authn-azure" authenticator with service id "test-service" and JSON:
    """
    {
      "provider-uri": "https://some-provider"
    }
    """
    And I POST "/authn-azure/test-service/cucumber/host" with body:
    """
    {
      "id": "test-host"
    }
    """
    Then the HTTP response status code is 422

  @acceptance @smoke
  Scenario: I initialize an OIDC authenticator host with name test-host
    When I persist an "authn-oidc" authenticator with service id "test-service" and JSON:
    """
    {
      "provider-uri": "https://some-provider",
      "id-token-user-property": "some-username"
    }
    """
    And I save my place in the audit log file for remote
    And I POST "/authn-oidc/test-service/cucumber/host" with body:
    """
    {
      "id": "test-host"
    }
    """
    Then the HTTP response status code is 201
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-oidc/test-service/apps
      body:
      - !host
        id: test-host

    - !grant
     role: !layer conjur/authn-oidc/test-service/users
     members:
       - !host conjur/authn-oidc/test-service/apps/test-host

    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:host:conjur/authn-oidc/test-service/apps/test-host"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="change"]
      [policy@43868 id="cucumber:policy:root" version="*"]
      cucumber:user:admin changed role cucumber:host:conjur/authn-oidc/test-service/apps/test-host
    """

  @acceptance
  Scenario: I initialize an OIDC authenticator host with extra annotations
    When I persist an "authn-oidc" authenticator with service id "test-service" and JSON:
    """
    {
      "provider-uri": "https://some-provider",
      "id-token-user-property": "some-username"
    }
    """
    And I save my place in the audit log file for remote
    And I POST "/authn-oidc/test-service/cucumber/host" with body:
    """
    {
      "id": "test-host",
      "annotations": {
        "extra-param": "extra"
      }
    }
    """
    Then the HTTP response status code is 201
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-oidc/test-service/apps
      body:
      - !host
        id: test-host
        annotations:
          extra-param: extra

    - !grant
     role: !layer conjur/authn-oidc/test-service/users
     members:
       - !host conjur/authn-oidc/test-service/apps/test-host

    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:host:conjur/authn-oidc/test-service/apps/test-host"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="change"]
      [policy@43868 id="cucumber:policy:root" version="*"]
      cucumber:user:admin changed role cucumber:host:conjur/authn-oidc/test-service/apps/test-host
    """

  @negative @acceptance
  Scenario: I attempt to initialize an authenticator host for a non-existent authenticator
    When I POST "/authn-oidc/non-existent-auth-service/cucumber/host" with body:
    """
    {
      "id": "test-host"
    }
    """
    Then the HTTP response status code is 404


  @acceptance
  Scenario: I initialize an GCP authenticator host
    When I persist an "authn-gcp" authenticator
    And I save my place in the audit log file for remote
    And I POST "/authn-gcp/cucumber/host" with body:
    """
    {
      "id": "test-host",
      "annotations": {
        "authn-gcp/project-id": "some project"
      }
    }
    """
    Then the HTTP response status code is 201
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-gcp/authenticator/apps
      body:
      - !host
        id: test-host
        annotations:
          authn-gcp/project-id: some project

    - !grant
     role: !layer conjur/authn-gcp/authenticator/users
     members:
       - !host conjur/authn-gcp/authenticator/apps/test-host

    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:host:conjur/authn-gcp/authenticator/apps/test-host"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="change"]
      [policy@43868 id="cucumber:policy:root" version="*"]
      cucumber:user:admin changed role cucumber:host:conjur/authn-gcp/authenticator/apps/test-host
      """


  Scenario: I initialize an GCP authenticator host
    When I persist an "authn-gcp" authenticator
    And I save my place in the audit log file for remote
    And I POST "/authn-gcp/cucumber/host" with body:
    """
    {
      "id": "test-host",
      "annotations": {
        "authn-gcp/project-id": "some project"
      }
    }
    """
    And I POST "/authn-gcp/cucumber/host" with body:
    """
    {
      "id": "test-host",
      "annotations": {
        "authn-gcp/project-id": "some project"
      }
    }
    """
    Then the HTTP response status code is 200
    And the YAML result is:
    """
    - !policy
      id: conjur/authn-gcp/authenticator/apps
      body:
      - !host
        id: test-host
        annotations:
          authn-gcp/project-id: some project

    - !grant
     role: !layer conjur/authn-gcp/authenticator/users
     members:
       - !host conjur/authn-gcp/authenticator/apps/test-host

    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:host:conjur/authn-gcp/authenticator/apps/test-host"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="change"]
      [policy@43868 id="cucumber:policy:root" version="*"]
      cucumber:user:admin changed role cucumber:host:conjur/authn-gcp/authenticator/apps/test-host
    """

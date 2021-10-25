Feature: JWT Authenticator - JWKs Basic sanity

  In this feature we define a JWT authenticator in policy and perform authentication
  with Conjur. In successful scenarios we will also define a variable and permit the host to
  execute it.

  Background:
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri

      - !variable
        id: token-app-property

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I successfully set authn-jwt "token-app-property" variable to value "sub"

  Scenario: DigDigDig - Sanity - Annotations
    Given I extend the policy with:
    """
    - !host
      id: system:serviceaccount:valid-namespace:valid-service-account
      annotations:
        authn-jwt/raw/kubernetes.io/namespace: valid-namespace
        authn-jwt/raw/kubernetes.io/pod/name: valid-pod-name

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host system:serviceaccount:valid-namespace:valid-service-account
    """
    Given I issue a JWT token:
    """
    {
      "kubernetes.io":
      {
        "namespace": "valid-namespace",
        "pod":
        {
          "name": "valid-pod-name",
          "uid": "aff9f397-663f-4851-b631-4c8c0537fbc0"
        },
        "serviceaccount":
        {
          "name": "valid-service-account",
          "uid": "ba2e9d9c-a046-45bc-becb-b21a7654de8a"
        }
      },
      "sub": "system:serviceaccount:valid-namespace:valid-service-account"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    system:serviceaccount:valid-namespace:valid-service-account successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: DigDigDig - Sanity - token-app-property
    Given I extend the policy with:
    """
    - !host
      id: valid-service-account
      annotations:
        authn-jwt/raw/sub: system:serviceaccount:valid-namespace:valid-service-account
        authn-jwt/raw/kubernetes.io/pod/name: valid-pod-name

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host valid-service-account
    """
    And I successfully set authn-jwt "token-app-property" variable to value "kubernetes.io/serviceaccount/name"
    And I issue a JWT token:
    """
    {
      "kubernetes.io":
      {
        "namespace": "valid-namespace",
        "pod":
        {
          "name": "valid-pod-name",
          "uid": "aff9f397-663f-4851-b631-4c8c0537fbc0"
        },
        "serviceaccount":
        {
          "name": "valid-service-account",
          "uid": "ba2e9d9c-a046-45bc-becb-b21a7654de8a"
        }
      },
      "sub": "system:serviceaccount:valid-namespace:valid-service-account"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    valid-service-account successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: DigDigDig - Enforced
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: system:serviceaccount:valid-namespace:valid-service-account
      annotations:
        authn-jwt/raw/kubernetes.io/namespace: valid-namespace
        authn-jwt/raw/kubernetes.io/pod/name: valid-pod-name

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host system:serviceaccount:valid-namespace:valid-service-account
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "kubernetes.io/pod/name"
    And I issue a JWT token:
    """
    {
      "kubernetes.io":
      {
        "namespace": "valid-namespace",
        "pod":
        {
          "name": "valid-pod-name",
          "uid": "aff9f397-663f-4851-b631-4c8c0537fbc0"
        },
        "serviceaccount":
        {
          "name": "valid-service-account",
          "uid": "ba2e9d9c-a046-45bc-becb-b21a7654de8a"
        }
      },
      "sub": "system:serviceaccount:valid-namespace:valid-service-account"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    system:serviceaccount:valid-namespace:valid-service-account successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: DigDigDig - Mapping
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims

    - !host
      id: system:serviceaccount:valid-namespace:valid-service-account
      annotations:
        authn-jwt/raw/namespace: valid-namespace
        authn-jwt/raw/pod: valid-pod-name

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host system:serviceaccount:valid-namespace:valid-service-account
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "pod:kubernetes.io/pod/name,namespace:kubernetes.io/namespace"
    And I issue a JWT token:
    """
    {
      "kubernetes.io":
      {
        "namespace": "valid-namespace",
        "pod":
        {
          "name": "valid-pod-name",
          "uid": "aff9f397-663f-4851-b631-4c8c0537fbc0"
        },
        "serviceaccount":
        {
          "name": "valid-service-account",
          "uid": "ba2e9d9c-a046-45bc-becb-b21a7654de8a"
        }
      },
      "sub": "system:serviceaccount:valid-namespace:valid-service-account"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    system:serviceaccount:valid-namespace:valid-service-account successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: DigDigDig - Enforced + Mapping
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims
    - !variable conjur/authn-jwt/raw/mapping-claims

    - !host
      id: system:serviceaccount:valid-namespace:valid-service-account
      annotations:
        authn-jwt/raw/namespace: valid-namespace
        authn-jwt/raw/pod: valid-pod-name

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host system:serviceaccount:valid-namespace:valid-service-account
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "kubernetes.io/pod/name"
    And I successfully set authn-jwt "mapping-claims" variable to value "pod:kubernetes.io/pod/name,namespace:kubernetes.io/namespace"
    And I issue a JWT token:
    """
    {
      "kubernetes.io":
      {
        "namespace": "valid-namespace",
        "pod":
        {
          "name": "valid-pod-name",
          "uid": "aff9f397-663f-4851-b631-4c8c0537fbc0"
        },
        "serviceaccount":
        {
          "name": "valid-service-account",
          "uid": "ba2e9d9c-a046-45bc-becb-b21a7654de8a"
        }
      },
      "sub": "system:serviceaccount:valid-namespace:valid-service-account"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    system:serviceaccount:valid-namespace:valid-service-account successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

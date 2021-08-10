Feature: JWT Authenticator - Token Schema

  Tests checking enforced claims and claims mapping

  Background:
    Given I load a policy:
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
    And I initialize remote JWKS endpoint with file "authn-jwt-token-schema" and alg "RS256"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-token-schema/RS256" in service "raw"
    And I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "token-app-property" variable to value "host"

  @sanity
  Scenario: ONYX-10471 - Enforced Claims Without Claims Mapping. Single enforced claim - 200 OK
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "ref":"valid",
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: ONYX-10471 - enforced Claims Without Claims Mapping. Two enforced claims - 200 OK
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid-ref
        authn-jwt/raw/sub: valid-sub

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref,sub"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "ref":"valid-ref",
      "sub":"valid-sub",
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: ONYX-10759 - enforced Claims Without Claims Mapping. Single enforced claim and wrong annotation - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "ref":"valid",
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00057E Role does not have the required constraints: '["ref"]'>
    """

  Scenario: ONYX-10760 - enforced Claims Without Claims Mapping. Single enforced claim but not in token - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00084E Claim 'ref' is missing from JWT token.
    """

  Scenario Outline: ONYX-10470 - Standard claim in mandatory claims - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "<claims>"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00105E Failed to validate claim: claim name '<err>' is in denylist '["iss", "exp", "nbf", "iat", "jti", "aud"]'
    """
    Examples:
    | claims        | err |
    |   iss         |  iss   |
    |   exp, iss    |  exp   |
    |   exp, branch |  exp   |

  Scenario Outline: ONYX-10857 - Standard claim in annotation - 401 Error
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/<claim>: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00069E Role can't have registered or mapped claim
    """
    Examples:
    | claim   |
    |   iat   |

  Scenario: ONYX-10860 - Enforced claims configured but not populated - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims
    - !variable conjur/authn-jwt/raw/mapping-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "ref":"valid",
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
     CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/enforced-claims
    """

  @sanity
  Scenario: ONYX-10891 - Complex Case - Adding Enforced Claim after host configuration
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: valid-sub

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "sub":"valid-sub",
      "ref":"valid-ref",
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """
    When I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00057E Role does not have the required constraints: '["ref"]'>
    """
    When I replace the "root" policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @sanity
  Scenario: ONYX-10472 Unrelated mapping
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project-id: valid-project
        authn-jwt/raw/namespace-id: valid-namespace

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project-id": "valid-project",
      "namespace-id": "valid-namespace"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @sanity
  Scenario: ONYX-10473 Mapping claims with subsequent annotation
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims
    
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project-id: valid-project
        authn-jwt/raw/branch: valid-branch

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project-id": "valid-project",
      "ref": "valid-branch"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: ONYX-10889 Complex Case - Adding Mapping after host configuration
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid-branch

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "ref": "valid-branch"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """
    When I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00069E Role can't have registered or mapped claim
    """

  @sanity
  Scenario: ONYX-10705: enforced Claims and Mappings exist and host annotation are correct
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/branch: valid-branch

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "ref": "valid-branch"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: ONYX-10816 - Enforced Claims with Claims Mapping. Single enforced claim but not in token - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims
    - !variable conjur/authn-jwt/raw/mapping-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/branch: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00084E Claim 'ref (annotation: branch)' is missing from JWT token. Verify that you configured the host with permitted restrictions
    """

  Scenario: ONYX-10874 - Claim being mapped to another claim - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: mysub

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "sub:ref"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "sub":"mysub",
      "ref":"mybranch"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'sub' does not match with the corresponding value in the request
    """

  Scenario: ONYX-10861 - Mapping claims configured but not populated - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "ref":"valid",
      "host":"myapp"
    }
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
     CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/mapping-claims
    """

  @sanity
  Scenario: ONYX-11117: Enforced Claims and Mappings with special allowed characters. Annotations are correct. 200 OK
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/claim.name: claim.name.value  # Only Enforce
        authn-jwt/raw/claim_ant: claim.ant...value # Map And Enforce
        authn-jwt/raw/_: claim_name_value # Only Map

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "claim_ant:claim.ant..., _:claim_name"
    And I successfully set authn-jwt "enforced-claims" variable to value "claim.name, claim.ant..."
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "claim.name": "claim.name.value",
      "claim.ant...": "claim.ant...value",
      "claim_name": "claim_name_value"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario Outline: ONYX-10873 - Broken claims mapping - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: mysub
        authn-jwt/raw/ref: myref

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "<mapping>"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "sub":"mysub",
      "ref":"mybranch"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    <err>
    """
    Examples:
      | mapping                     | err                                                                             |
      |   branch: ref, branch:sub   | CONJ00113E Failed to parse mapping claims: annotation name value 'branch' appears more than once |
      |   branch: sub, job: sub     | CONJ00113E Failed to parse mapping claims: claim name value 'sub' appears more than once   |

  Scenario Outline: ONYX-10858 - Standard claim in mapping - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: mysub
        authn-jwt/raw/ref: myref

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "<mapping>"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "sub":"mysub",
      "ref":"mybranch"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00105E Failed to validate claim: claim name 'exp' is in denylist '["iss", "exp", "nbf", "iat", "jti", "aud"]
    """
    Examples:
      | mapping        |
      |   branch: exp  |
      |   exp: sub     |

  Scenario: ONYX-10862 - Enforced claim invalid variable - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "%@^#[{]}$~=-+_?.><&^@*@#*sdhj812ehd"
    And I permit host "myapp" to "execute" it
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "ref":"valid",
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00104E Failed to validate claim: claim name '%@^#[{]}$~=-+_?.><&^@*@#*sdhj812ehd' does not match regular expression: '(?-mix:^[a-zA-Z|$|_][a-zA-Z|$|_|0-9|.]*$)'.>
    """

  Scenario: ONYX-10863 - Mapping claims invalid variable - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "aaa: %@^#&^[{]}$~=-+_?.><812ehd"
    And I permit host "myapp" to "execute" it
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "ref":"valid",
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00104E Failed to validate claim: claim name '%@^#&^[{]}$~=-+_?.><812ehd' does not match regular expression: '(?-mix:^[a-zA-Z|$|_][a-zA-Z|$|_|0-9|.]*$)'.
    """

  Scenario: ONYX-10941:  Complex Case - Add mapping of mandatory claims after host configuration
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid-ref

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "ref": "valid-ref"
    }
    """
    And I authenticate via authn-jwt with the JWT token
    And the HTTP response status code is 200
    And I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I save my place in the audit log file
    And I authenticate via authn-jwt with the JWT token
    And the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00057E Role does not have the required constraints: '["branch"]'
    """
    And I update the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/branch: valid-ref
    """
    And I save my place in the audit log file
    And I authenticate via authn-jwt with the JWT token
    And the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00069E Role can't have one of these none permitted restrictions '["ref"]'
    """
    When I update the policy with:
    """
    - !delete
      record: !host myapp
    """
    And I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/branch: valid-ref

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I save my place in the audit log file
    And I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: ONYX-10896:  Authn JWT - Complex Case - Changing Mapping after host configuration
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/branch: valid-ref

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I am using file "authn-jwt-token-schema" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "ref": "valid-ref"
    }
    """
    And I authenticate via authn-jwt with the JWT token
    And the HTTP response status code is 200
    When I successfully set authn-jwt "mapping-claims" variable to value "job:ref"
    And I save my place in the audit log file
    And I authenticate via authn-jwt with the JWT token
    And the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00084E Claim 'branch' is missing from JWT token. Verify that you configured the host with permitted restrictions.
    """
    When I update the policy with:
    """
    - !delete
      record: !host myapp
    """
    And I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/job: valid-ref

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I save my place in the audit log file
    And I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

@api @skip
Feature: API key for host is created and removed based on host's annotation
  Background:
    Given I am the super-user

  Scenario: Host Creation with true annotation impacts API key
    Given I have host "optional"
    Then the role "cucumber:host:optional" has non-empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 200

  Scenario: Host Creation with false annotation impacts API key
    Given I have host "optional" without api key
    Then the role "cucumber:host:optional" has empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 401

  Scenario: Host Creation via wrapper with true annotation impacts API key
    Given I set the "Content-Type" header to "application/json"
    And I successfully POST "/hosts/cucumber/root" with body:
    """
    { "id": "optional", "annotations": { "authn/api-key": "true" } }
    """
    Then the role "cucumber:host:optional" has non-empty API key

  Scenario: Host Creation via wrapper with false annotation impacts API key
    Given I set the "Content-Type" header to "application/json"
    And I successfully POST "/hosts/cucumber/root" with body:
    """
    { "id": "optional", "annotations": { "authn/api-key": "false" } }
    """
    Then the role "cucumber:host:optional" has empty API key

  Scenario: Host Creation via wrapper with no annotation impacts API key
    Given I set the "Content-Type" header to "application/json"
    And I successfully POST "/hosts/cucumber/root" with body:
    """
    { "id": "optional" }
    """
    Then the role "cucumber:host:optional" has empty API key

  Scenario: Only Host Annotation authn/api-key Modification impacts API key
    Given I have host "optional"
    Then the role "cucumber:host:optional" has non-empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 200
    When I set annotation "other-annotation" to "false" on role "cucumber:host:optional"
    Then the role "cucumber:host:optional" has non-empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 200
    When I set annotation "authn/api-key" to "false" on role "cucumber:host:optional"
    Then the role "cucumber:host:optional" has empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 401
    When I set annotation "other-annotation" to "true" on role "cucumber:host:optional"
    Then the role "cucumber:host:optional" has empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 401
    When I set annotation "authn/api-key" to "true" on role "cucumber:host:optional"
    Then the role "cucumber:host:optional" has non-empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 200

  Scenario: Only Host Annotation authn/api-key Addition impacts API key
    Given I have host "optional" without api key
    Then the role "cucumber:host:optional" has empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 401
    When I set annotation "other-annotation" to "true" on role "cucumber:host:optional"
    Then the role "cucumber:host:optional" has empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 401
    When I set annotation "authn/api-key" to "true" on role "cucumber:host:optional"
    Then the role "cucumber:host:optional" has non-empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 200

  Scenario: Host Annotation Removal impacts API key
    Given I have host "optional"
    Then the role "cucumber:host:optional" has non-empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 200
    When I remove all annotations from host "optional"
    Then the role "cucumber:host:optional" has empty API key
    When I POST "/authn/cucumber/host%2Foptional/authenticate" with plain text body ":cucumber:host:optional_api_key"
    Then the HTTP response status code is 401

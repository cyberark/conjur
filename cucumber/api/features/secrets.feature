@logged-in
Feature: Adding and fetching secrets

  Background:
    Given I create a new resource

  Scenario: When I create a new resource has no secrets, fetching the secret results in a 404 error.
    When I GET "/secrets/:account/:resource_kind/:resource_id"
    Then it's not found

  Scenario: The 'conjur/mime_type' annotation is used in the value response.
    Given I set annotation "conjur/mime_type" to "application/json"
    And I successfully POST "/secrets/:account/:resource_kind/:resource_id" with body:
    """
    [ "v-1" ]
    """
    When I successfully GET "/secrets/:account/:resource_kind/:resource_id"
    Then the JSON should be:
    """
    [ "v-1" ]
    """

  Scenario: Secrets can contain any binary data.
    Given I create a binary secret value
    When I successfully GET "/secrets/:account/:resource_kind/:resource_id"
    Then the binary result is preserved

  Scenario: When fetching a secret, the last secret in the secrets list is the default.
    Given I successfully POST "/secrets/:account/:resource_kind/:resource_id" with body:
    """
    v-1
    """
    And I successfully POST "/secrets/:account/:resource_kind/:resource_id" with body:
    """
    v-2
    """
    When I successfully GET "/secrets/:account/:resource_kind/:resource_id"
    Then the binary result is "v-2"

  Scenario: When fetching a secret, a specific secret index can be specified.
    Given I successfully POST "/secrets/:account/:resource_kind/:resource_id" with body:
    """
    v-1
    """
    And I successfully POST "/secrets/:account/:resource_kind/:resource_id" with body:
    """
    v-2
    """
    When I successfully GET "/secrets/:account/:resource_kind/:resource_id?version=1"
    Then the binary result is "v-1"

  Scenario: When fetching a secret, a non-existant secret version is not accepted.
    Given I successfully POST "/secrets/:account/:resource_kind/:resource_id" with body:
    """
    v-1
    """
    When I GET "/secrets/:account/:resource_kind/:resource_id?version=2"
    Then it's not found

  Scenario: When creating a secret, the value parameter is required.
    When I POST "/secrets/:account/:resource_kind/:resource_id" with body:
    """
    """
    Then it's unprocessable

  Scenario: Only the last 20 versions of a secret are stored
    Given I create 20 secret values
    And I successfully POST "/secrets/:account/:resource_kind/:resource_id" with body:
    """
    v-21
    """
    When I GET "/secrets/:account/:resource_kind/:resource_id?version=1"
    Then it's not found

@logged-in
Feature: Adding and fetching secrets

  Background:
  	Given a resource

  Scenario: When a resource has no secrets, fetching the secret results in a 404 error.
    When I GET "/secrets/:account/:resource_kind/:resource_id"
    Then it's not found

  Scenario: The 'conjur/mime_type' annotation is used in the value response.
  	And I set annotation "conjur/mime_type" to "application/json"
    And I successfully POST "/secrets/:account/:resource_kind/:resource_id" with parameters:
    """
    value: '[ "v-1" ]'
    """
    When I successfully GET "/secrets/:account/:resource_kind/:resource_id"
    Then the JSON should be:
    """
    [ "v-1" ]
    """

  Scenario: When fetching a secret, the last secret in the secrets list is the default.
    And I successfully POST "/secrets/:account/:resource_kind/:resource_id" with parameters:
    """
    value: v-1
    """
    And I successfully POST "/secrets/:account/:resource_kind/:resource_id" with parameters:
    """
    value: v-2
    """
    When I successfully GET "/secrets/:account/:resource_kind/:resource_id"
    Then the "text/plain" result is "v-2"

  Scenario: When fetching a secret, a specific secret index can be specified.
    And I successfully POST "/secrets/:account/:resource_kind/:resource_id" with parameters:
    """
    value: v-1
    """
    And I successfully POST "/secrets/:account/:resource_kind/:resource_id" with parameters:
    """
    value: v-2
    """
    When I successfully GET "/secrets/:account/:resource_kind/:resource_id?version=1"
    Then the "text/plain" result is "v-1"

  Scenario: When fetching a secret, a non-existant secret version is not accepted.
    And I successfully POST "/secrets/:account/:resource_kind/:resource_id" with parameters:
    """
    value: v-1
    """
    When I GET "/secrets/:account/:resource_kind/:resource_id?version=2"
    Then it's not found

  Scenario: When creating a secret, the value parameter is required.
    When I POST "/secrets/:account/:resource_kind/:resource_id" with parameters:
    """
    """
    Then it's unprocessable
    When I POST "/secrets/:account/:resource_kind/:resource_id" with parameters:
    """
    value: ''
    """
    Then it's unprocessable

  Scenario: Only the last 20 versions of a secret are stored
  	Given I create 20 secret values
    And I successfully POST "/secrets/:account/:resource_kind/:resource_id" with parameters:
    """
    value: v-21
    """
    When I GET "/secrets/:account/:resource_kind/:resource_id?version=1"
    Then it's not found

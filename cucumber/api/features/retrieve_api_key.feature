@api
Feature: Retrieving an API key with conjurctl

  Background:
    # We need to be in production environment to test this to demonstrate a real use-case
    Given I set environment variable "RAILS_ENV" to "production"
    And I set environment variable "CONJUR_LOG_LEVEL" to "info"

  @smoke
  Scenario: Retrieve an API key
    When I retrieve an API key for user "cucumber:user:admin" using conjurctl
    Then the API key is correct

  @negative @acceptance
  Scenario: Retrieve an API key of a non-existing user fails
    When I retrieve an API key for user "cucumber:user:non-existing-user" using conjurctl
    Then the stderr includes the error "role does not exist"

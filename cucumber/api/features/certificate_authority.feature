@api
Feature: Conjur signs certificates using a configured CA

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: conjur/kitchen/ca
      body:
        - !variable private-key
        - !variable cert-chain

        - !webservice
          annotations:
            ca/private-key: conjur/kitchen/ca/private-key
            ca/certificate-chain: conjur/kitchen/ca/cert-chain
            ca/max_ttl: P1Y

        - !group clients

        - !permit
          role: !group clients
          privilege: [ sign ]
          resource: !webservice

    - !host bacon
    - !host toast
    - !user alice

    - !grant
      role: !group conjur/kitchen/ca/clients
      member: !host bacon

    - !policy
      id: conjur/dining-room/ca
      body:
        - !variable private-key
        - !variable private-key-password
        - !variable cert-chain

        - !webservice
          annotations:
            ca/private-key: conjur/dining-room/ca/private-key
            ca/private-key-password: conjur/dining-room/ca/private-key-password
            ca/certificate-chain: conjur/dining-room/ca/cert-chain
            ca/max_ttl: P1Y

    - !host table
    - !permit
      role: !host table
      privilege: [ sign ]
      resource: !webservice conjur/dining-room/ca
    """
    And the HTTP response content type is "application/json"
    And I have an intermediate CA "kitchen"
    And I add the "kitchen" intermediate CA private key to the resource "cucumber:variable:conjur/kitchen/ca/private-key"
    And I add the "kitchen" intermediate CA cert chain to the resource "cucumber:variable:conjur/kitchen/ca/cert-chain"
    And I have an intermediate CA "dining-room" with password "secret"
    And I add the "dining-room" intermediate CA private key to the resource "cucumber:variable:conjur/dining-room/ca/private-key"
    And I add the "dining-room" intermediate CA cert chain to the resource "cucumber:variable:conjur/dining-room/ca/cert-chain"
    And I add the secret value "secret" to the resource "cucumber:variable:conjur/dining-room/ca/private-key-password"

  @negative @acceptance
  Scenario: A non-existent ca returns a 404
    When I POST "/ca/cucumber/living-room/sign"
    Then the HTTP response status code is 404

  @negative @acceptance
  Scenario: A login that isn't a host returns a 403
    When I POST "/ca/cucumber/kitchen/sign"
    Then the HTTP response status code is 403

  @negative @acceptance
  Scenario: The service returns 403 Forbidden if the host doesn't have sign privileges
    Given I login as "cucumber:host:toast"
    When I send a CSR for "toast" to the "kitchen" CA with a ttl of "P6M" and CN of "toast"
    Then the HTTP response status code is 403

  @smoke
  Scenario: I can sign a valid CSR with a configured Conjur CA
    Given I login as "cucumber:host:bacon"
    When I send a CSR for "bacon" to the "kitchen" CA with a ttl of "P6M" and CN of "bacon"
    Then the HTTP response status code is 201
    And the HTTP response content type is "application/json"
    And the resulting json certificate is valid according to the "kitchen" intermediate CA

  @acceptance
  Scenario: I can receive the result directly as a PEM formatted certificate
    Given I login as "cucumber:host:bacon"
    And I set the "Accept" header to "application/x-pem-file"
    When I send a CSR for "bacon" to the "kitchen" CA with a ttl of "P6M" and CN of "bacon"
    Then the HTTP response status code is 201
    And the HTTP response content type is "application/x-pem-file"
    And the resulting pem certificate is valid according to the "kitchen" intermediate CA
    And the common name is "cucumber:kitchen:host:bacon"
    And the subject alternative names contain "DNS:bacon"
    And the subject alternative names contain "URI:spiffe://conjur/cucumber/kitchen/host/bacon"

  @acceptance
  Scenario: I can sign a CSR using an encrypted CA private key
    Given I login as "cucumber:host:table"
    When I send a CSR for "table" to the "dining-room" CA with a ttl of "P6M" and CN of "table"
    Then the HTTP response status code is 201
    And the HTTP response content type is "application/json; charset=utf-8"
    And the resulting json certificate is valid according to the "dining-room" intermediate CA

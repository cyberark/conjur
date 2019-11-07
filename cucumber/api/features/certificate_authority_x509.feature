Feature: Conjur signs certificates using a configured CA

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: conjur/ca/kitchen
      body:
        - !variable private-key
        - !variable cert-chain

        - !webservice
          annotations:
            ca/private-key: conjur/ca/kitchen/private-key
            ca/certificate: conjur/ca/kitchen/cert-chain
            ca/max-ttl: P1Y

        - !group clients

        - !permit
          role: !group clients
          privilege: [ sign ]
          resource: !webservice

    - !host bacon
    - !host toast
    - !user alice

    - !grant
      role: !group conjur/ca/kitchen/clients
      member: !host bacon

    - !policy
      id: conjur/ca/dining-room
      body:
        - !variable private-key
        - !variable private-key-password
        - !variable cert-chain

        - !webservice
          annotations:
            ca/private-key: conjur/ca/dining-room/private-key
            ca/private-key-password: conjur/ca/dining-room/private-key-password
            ca/certificate: conjur/ca/dining-room/cert-chain
            ca/max-ttl: P1Y

    - !host table
    - !permit
      role: !host table
      privilege: [ sign ]
      resource: !webservice conjur/ca/dining-room
    """
    And I have an intermediate CA "kitchen"
    And I add the "kitchen" intermediate CA private key to the resource "cucumber:variable:conjur/ca/kitchen/private-key"
    And I add the "kitchen" intermediate CA cert chain to the resource "cucumber:variable:conjur/ca/kitchen/cert-chain"
    And I have an intermediate CA "dining-room" with password "secret"
    And I add the "dining-room" intermediate CA private key to the resource "cucumber:variable:conjur/ca/dining-room/private-key"
    And I add the "dining-room" intermediate CA cert chain to the resource "cucumber:variable:conjur/ca/dining-room/cert-chain"
    And I add the secret value "secret" to the resource "cucumber:variable:conjur/ca/dining-room/private-key-password"

  Scenario: A non-existent ca returns a 404
    When I POST "/ca/cucumber/living-room/certificates"
    Then the HTTP response status code is 404

  Scenario: A login that isn't a host returns a 422
    When I POST "/ca/cucumber/kitchen/certificates"
    Then the HTTP response status code is 422

  Scenario: The service returns 403 Forbidden if the host doesn't have sign privileges
    Given I login as "cucumber:host:toast"
    When I send a CSR for "toast" to the "kitchen" CA with a ttl of "P6M" and CN of "toast"
    Then the HTTP response status code is 403

  Scenario: I can sign a valid CSR with a configured Conjur CA
    Given I login as "cucumber:host:bacon"
    When I send a CSR for "bacon" to the "kitchen" CA with a ttl of "P6M" and CN of "bacon"
    Then the HTTP response status code is 201
    And the HTTP response content type is "application/x-pem-file"
    And the resulting pem certificate is valid according to the "kitchen" intermediate CA
    And the common name is "cucumber:kitchen:host:bacon"
    And the subject alternative names contain "DNS:bacon"
    And the subject alternative names contain "URI:spiffe://conjur/cucumber/kitchen/host/bacon"

  Scenario: I can sign a CSR using an encrypted CA private key
    Given I login as "cucumber:host:table"
    When I send a CSR for "table" to the "dining-room" CA with a ttl of "P6M" and CN of "table"
    Then the HTTP response status code is 201
    And the resulting pem certificate is valid according to the "dining-room" intermediate CA

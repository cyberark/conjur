Feature: Conjur signs certificates using a configured CA

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: conjur/ca/delegator
      body:
        - !variable private-key
        - !variable cert-chain

        - !webservice
          annotations:
            ca/private-key: conjur/ca/delegator/private-key
            ca/certificate: conjur/ca/delegator/cert-chain
            ca/max-ttl: P1Y
            ca/ca-use-permitted: true

        - !group clients

        - !permit
          role: !group clients
          privilege: [ sign ]
          resource: !webservice

    - !host
      id: intermediate-ca-a
      annotations:
        ca/delegator/ca-use-permitted: true

    - !host
      id: intermediate-ca-b
      annotations:
        ca/delegator/ca-use-permitted: false

    - !host
      id: intermediate-ca-c

    - !grant
      role: !group conjur/ca/delegator/clients
      members:
        - !host intermediate-ca-a
        - !host intermediate-ca-b
        - !host intermediate-ca-c
    """
    And I have an intermediate CA "delegator"
    And I add the "delegator" intermediate CA private key to the resource "cucumber:variable:conjur/ca/delegator/private-key"
    And I add the "delegator" intermediate CA cert chain to the resource "cucumber:variable:conjur/ca/delegator/cert-chain"

  Scenario: I can sign a valid CA CSR with a configured Conjur CA
    Given I login as "cucumber:host:intermediate-ca-a"
    When I send a "ca" CSR for "intermediate-ca-a" to the "delegator" CA with a ttl of "P6M" and CN of "intermediate-ca-a"
    Then the HTTP response status code is 201
    And the HTTP response content type is "application/x-pem-file"
    And the resulting pem certificate is valid according to the "delegator" intermediate CA
    And the "basicConstraints" extension is "CA:TRUE, pathlen:0"

  Scenario: The service returns 403 Forbidden if the host doesn't have ca request privileges
    Given I login as "cucumber:host:intermediate-ca-b"
    When I send a "ca" CSR for "intermediate-ca-b" to the "delegator" CA with a ttl of "P6M" and CN of "intermediate-ca-b"
    Then the HTTP response status code is 403

  Scenario: The service returns 403 Forbidden if the host does not have explicit CA privileges
    Given I login as "cucumber:host:intermediate-ca-c"
    When I send a "ca" CSR for "intermediate-ca-c" to the "delegator" CA with a ttl of "P6M" and CN of "intermediate-ca-c"
    Then the HTTP response status code is 403

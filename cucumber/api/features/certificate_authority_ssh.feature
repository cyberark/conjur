Feature: Conjur signs certificates using a configured CA

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: conjur/ca/petstore
      body:
        - !variable private-key
        - !variable public-key

        - !webservice
          annotations:
            ca/private-key: conjur/ca/petstore/private-key
            ca/certificate: conjur/ca/petstore/public-key
            ca/max-ttl: P1D
            ca/kind: ssh

        - !group clients

        - !permit
          role: !group clients
          privilege: [ sign ]
          resource: !webservice

    - !host web
    - !host db
    - !user alice

    - !grant
      role: !group conjur/ca/petstore/clients
      members:
      - !host web
      - !user alice

    #-------------------------------------

    - !policy
      id: conjur/ca/petstore-encrypted
      body:
        - !variable private-key
        - !variable private-key-password
        - !variable public-key

        - !webservice
          annotations:
            ca/private-key: conjur/ca/petstore-encrypted/private-key
            ca/private-key-password: conjur/ca/petstore-encrypted/private-key-password
            ca/certificate: conjur/ca/petstore-encrypted/public-key
            ca/max-ttl: P1D
            ca/kind: ssh

    - !host table
    - !permit
      role: !host table
      privilege: [ sign ]
      resource: !webservice conjur/ca/petstore-encrypted
    """
    And I have an ssh CA "petstore"
    And I add the "petstore" ssh CA private key to the resource "cucumber:variable:conjur/ca/petstore/private-key"
    And I add the "petstore" ssh CA public key to the resource "cucumber:variable:conjur/ca/petstore/public-key"

    And I have an ssh CA "petstore-encrypted" with password "secret"
    And I add the "petstore-encrypted" ssh CA private key to the resource "cucumber:variable:conjur/ca/petstore-encrypted/private-key"
    And I add the "petstore-encrypted" ssh CA public key to the resource "cucumber:variable:conjur/ca/petstore-encrypted/public-key"
    And I add the secret value "secret" to the resource "cucumber:variable:conjur/ca/petstore-encrypted/private-key-password"

  Scenario: The service returns 403 Forbidden if the host doesn't have sign privileges
    Given I login as "cucumber:host:db"
    When I send a public key for "db" to the "petstore" CA with a ttl of "P1D"
    Then the HTTP response status code is 403

  Scenario: I can sign an SSH public key with a configured Conjur SSH CA
    Given I login as "cucumber:host:web"
    When I send a public key for "web" to the "petstore" CA with a ttl of "P1D"
    Then the HTTP response status code is 201
    And the HTTP response content type is "application/x-openssh-file"
    And the resulting openssh certificate is valid according to the "petstore" ssh CA

  Scenario: I can sign an SSH public key using an encrypted SSH private key
    Given I login as "cucumber:host:table"
    When I send a public key for "table" to the "petstore-encrypted" CA with a ttl of "P1D"
    Then the HTTP response status code is 201
    And the resulting openssh certificate is valid according to the "petstore-encrypted" ssh CA

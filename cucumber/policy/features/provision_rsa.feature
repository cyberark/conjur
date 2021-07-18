Feature: Variables can be provisioned as RSA private keys

  Scenario: An LDAP user authorized in Conjur can login with a good password using TLS
    Given a policy document:
    """
    - !variable
      id: provisioned/rsa-private-key
      annotations:
        provision/provisioner: rsa
        provision/rsa/length: 2048
      
    """
    When I load the policy into 'root'
    Then I can fetch a secret from variable resource "provisioned/rsa-private-key"
    And the result contains:
    """
    -----BEGIN PRIVATE KEY-----
    """

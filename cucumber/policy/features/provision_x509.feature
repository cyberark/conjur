Feature: Variables can be provisioned as X509 certificate or signing requests

  Scenario: Generate a CSR for a store private key
    Given a policy document:
    """
    - !variable
      id: provisioned/ca/private-key
      annotations:
        provision/provisioner: rsa
        provision/rsa/length: 2048

    - !variable
      id: provisioned/ca/csr
      annotations:
        provision/provisioner: x509-csr
        provision/x509-csr/private-key-variable: provisioned/ca/private-key
        provision/x509-csr/subject/cn: conjur-master
    """
    When I load the policy into 'root'
    Then I can fetch a secret from variable resource "provisioned/ca/csr"
    And the result contains:
    """
    -----BEGIN CERTIFICATE REQUEST-----
    """

  Scenario: Issue a self-signed x509 certificate
    Given a policy document:
    """
    - !variable
      id: provisioned/ca/private-key
      annotations:
        provision/provisioner: rsa
        provision/rsa/length: 2048

    - !variable
      id: provisioned/ca/self-signed-cert
      annotations:
        provision/provisioner: x509-certificate
        provision/x509-certificate/subject/cn: conjur-master-ca
        provision/x509-certificate/subject/c: US
        provision/x509-certificate/basic-constraints/ca: true
        provision/x509-certificate/basic-constraints/pathlen: 0
        provision/x509-certificate/basic-constraints/critical: true
        provision/x509-certificate/key-usage/critical: true
        provision/x509-certificate/key-usage/key-cert-sign: true
        provision/x509-certificate/key-usage/crl-sign: true
        provision/x509-certificate/private-key/variable: provisioned/ca/private-key
        provision/x509-certificate/issuer/private-key/variable: provisioned/ca/private-key
        provision/x509-certificate/issuer/certificate/self: true
        provision/x509-certificate/ttl: P1D
    """
    When I load the policy into 'root'
    Then I can fetch a secret from variable resource "provisioned/ca/self-signed-cert"
    And the result contains:
    """
    -----BEGIN CERTIFICATE-----
    """

  Scenario: Issue an x509 certificate from a CA cert
    Given a policy document:
    """
    - !variable
      id: provisioned/ca/private-key
      annotations:
        provision/provisioner: rsa
        provision/rsa/length: 2048

    - !variable
      id: provisioned/ca/cert
      annotations:
        provision/provisioner: x509-certificate
        provision/x509-certificate/subject/cn: conjur-master-ca
        provision/x509-certificate/subject/c: US
        provision/x509-certificate/basic-constraints/ca: true
        provision/x509-certificate/basic-constraints/pathlen: 0
        provision/x509-certificate/basic-constraints/critical: true
        provision/x509-certificate/key-usage/critical: true
        provision/x509-certificate/key-usage/key-cert-sign: true
        provision/x509-certificate/key-usage/crl-sign: true
        provision/x509-certificate/private-key/variable: provisioned/ca/private-key
        provision/x509-certificate/issuer/private-key/variable: provisioned/ca/private-key
        provision/x509-certificate/issuer/certificate/self: true
        provision/x509-certificate/ttl: P1D

    - !variable
      id: provisioned/server/private-key
      annotations:
        provision/provisioner: rsa
        provision/rsa/length: 2048

    - !variable
      id: provisioned/server/certificate
      annotations:
        provision/provisioner: x509-certificate
        provision/x509-certificate/subject/cn: server
        provision/x509-certificate/subject/c: US
        provision/x509-certificate/key-usage/critical: true
        provision/x509-certificate/key-usage/key-encipherment: true
        provision/x509-certificate/private-key/variable: provisioned/server/private-key
        provision/x509-certificate/issuer/private-key/variable: provisioned/ca/private-key
        provision/x509-certificate/issuer/certificate/variable: provisioned/ca/cert
        provision/x509-certificate/ttl: P1D
    """
    When I load the policy into 'root'
    Then I can fetch a secret from variable resource "provisioned/server/certificate"
    And the result contains:
    """
    -----BEGIN CERTIFICATE-----
    """

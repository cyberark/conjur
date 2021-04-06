# Certificate Signing - Overview

Certificate authority (CA) signing in Conjur adds support for signing
host certificates using a CA certificate and private key stored in
Conjur.

A primary use case this supports is configuring mutual TLS between
hosts with resource restrictions provisioned in Conjur. In this scenario,
Conjur operators can configure a signing CA in conjur with a key and
issuer certificate created outside of Conjur. Hosts may be granted
the privilege to sign their own short-lived certificate through the CA.
This host certificate can then be used to identify the service to
other hosts or systems that trust the issuing CA.

## Getting Started

To begin signing host certificates you need:

- A running Conjur instance
- A policy to configure the CA and hosts to request certificates
- A certificate chain and private key for the issuer CA

### Policy for Conjur CAs

The policy for configuring a Conjur Certificate authority begins with
a `webservice` entity with a well-known id of the form
`conjur/<ca-service-id>/ca`. The CA is configured using well-known
annotations. A minimal CA policy might look like:
```
- !variable my-issuer/private-key
- !variable my-issuer/private-key-password
- !variable my-issuer/certificate-chain

- !webservice
    id: conjur/my-issuer/ca
    annotations:
      ca/private-key: my-issuer/private-key
      ca/private-key-password: my-issuer/private-key-password
      ca/certificate-chain: my-issuer/certificate-chain
      ca/max_ttl: P1M
```

- **ca/private-key** (required): Name of conjur variable that contains
  the PEM encoded CA private key.
- **ca/private-key-password** (optional): Name of conjur variable that
  the password for the private key.
     > This is only necessary if the key is encrypted when loaded into
     > Conjur.
- **ca/certificate-chain** (required): Name of conjur variable that
  contains the PEM encoded certificate chain for the issuer.
- **ca/max_ttl** (required): Value of max allow TTL in
  [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) format.

A complete CA policy would also include a group or layer for permitting
hosts to submit certificate signing requests (CSRs). An example would be:
```
- !policy 
  id: conjur/<service-id>/ca
  body:
    # Signed certificates will be valid for up to a year
    - !webservice
        annotations:
          ca/private-key: ops/ca/private-key
          ca/private-key-password: ops/ca/private-key-password # If the import PEM key is encrypted
          ca/certificate-chain: ops/ca/private-key-chain
          ca/max_ttl: P1M

    - !group clients

    # Allow hosts in the `clients` group to be signed
    - !permit
      role: !group clients
      privilege: [ sign ]
      resource: !webservice
```

### Generate an Intermediate CA Private Key and Certificate Chain

Conjur CAs require the issuing private key and certificate to be
generated outside of Conjur. A good walk through of creating a 
root CA and then an intermediate CA that may be used in conjur is
available [here](https://jamielinux.com/docs/openssl-certificate-authority/index.html).

### Signing Host Certificates

Once the CA is configured in Conjur and a host has `sign` privileges,
then a host may submit a CSR to the CA endpoint for signing:

- The host first needs to generate its own private key and a
  certificate signing request (CSR).

- The host must be authenticated to conjur, and then POST the PEM
  encoded CSR to `/ca/<account>/<ca_id>/sign`

- If the CSR is valid and the host is authorized, then the CA
  will respond with the PEM encoded certificate.
  
- The CA will assign the follow subject data on the issued certificate:
  - The common name (CN) will have the form
    `{account}:{ca_service_id}:host:{host_id}`.
  - A DNS subject alternative name will be added with the leaf
    portion of the host. e.g. a host with id `production/cart/srv-01`
    will include a DNS subject alternative name of `srv-01`.
  - A SPIFFE SVID URI subject alternative name will be added of the form
    `spiffe://conjur/{account}/{ca_service_id}/host/{host_id}`

A full example of certificate signing is available
[here](https://github.com/conjurdemos/misc-util/tree/master/demos/certificate-authority/mutual-tls)

# Certificate Signing - Overview

Version: Alpha

Implementation Owner:
@micahlee

## Motivation

Digital certificates are a useful mechanism for authentication, data
integrity, and data confidentiality. Certificates offer many advantages
over other options such as passwords, API keys, or public/private key
pairs because they are revokable, have built-in mechanisms for validity
checking, may include attributes describing the subject they identify,
and most importantly, they can be signed by a trusted authority.

The use of trusted authorities, and a public key infrastructure (PKI)
make digital certificates (and certificate signing) a cornerstone of
flexible and scalable access control architecture.

Managing private key material for trusted authorities, and controlling
and auditing the use of signatures can be complicated and risky.
Certificate signing in Conjur is a capability intended to leverage the
existing role and strengths of Conjur in an authorization architecture
to promote the safe and effective use digital certificates.

## Use Cases

Conjur certificate authorities may be used to sign digital certificates
addressing 4 use cases:

1. **TLS Host Certificates**
2. **TLS Client Certificates**
3. **SSH Host Certificates**
4. **SSH Client Certificates**

## Getting Started with Conjur Certificate Authorities

All Conjur Certificate Authorities (CA's) begin with a policy
definition and a private key.

### Create a Private Key
In the alpha version, Conjur certificate authorities only support
RSA private keys in PEM format. A valid private key may be created
either using `openssl` or `ssh-keygen`:
```sh
openssl genrsa -aes256 -out private_key_file 4096 
```
```
ssh-keygen -t rsa -m pem -f private_key_file
```

### (x.509) Create a Signing Certificate

Conjur CAs in the alpha version requre the issuer certificate to be
generated outside of Conjur. A good walk through of creating a either
a self-signed root CA certificate or an intermediate CA certificate
that may be used in conjur is available
[here](https://jamielinux.com/docs/openssl-certificate-authority/index.html).

### Define a Certificate Authority in Conjur Policy

A Conjur Certificate Authority is creating in Conjur by defining
a `webservice` entity with a well-known identifier of the form
```
conjur/ca/<service_id>
```
where `<service_id>` is any value you choose.

The certificate authority is configured with annotations on the
`webservice`. The available configuration options are:

- `ca/private-key` (Required)
  <br/> Id of conjur variable that contains the PEM encoded CA private key.

- `ca/private-key-password` (Optional)
  <br/> Id of conjur variable that contains the password for the private key.

- `ca/certificate` (Required for x.509 Certificate Authorities)
  <br/> Id of conjur variable that contains the PEM encoded certificate
        for the issuer. This may include the certificate chain of trust
        to a root CA.

- `ca/public-key` (Required for SSH Certificate Authorities)
  <br/> Id of conjur variable that contains the OpenSSH encoded public key
        for the issuer.
  > The SSH public key is currently unused, but may be provided in the future
  > to make it easier to establish trust with the Conjur SSH CA.

- `ca/max-ttl` (Required)
  <br/> Value of max allowed TTL in [ISO8601](https://en.wikipedia.org/wiki/ISO_8601)
        format.

<details><summary>Example Certificate Authority Policy</summary>
<p>

```yaml
- !variable my-issuer/private-key
- !variable my-issuer/private-key-password
- !variable my-issuer/certificate-chain

- !webservice
    id: conjur/my-issuer/ca
    annotations:
      ca/private-key: my-issuer/private-key
      ca/private-key-password: my-issuer/private-key-password
      ca/certificate: my-issuer/certificate-chain
      ca/max_ttl: P1M
```
</p>
</details>

The recommended CA policy also includes a group for permitting hosts and users
to submit certificate signing requests (CSRs). 

<details><summary>Example Recommended Certificate Authority Policy</summary>
<p>

```yaml
- !policy 
  id: conjur/<service-id>/ca
  body:
    # Signed certificates will be valid for up to a year
    - !webservice
        annotations:
          ca/private-key: ops/ca/private-key
          ca/private-key-password: ops/ca/private-key-password # If the import PEM key is encrypted
          ca/certificate: ops/ca/private-key-chain
          ca/max_ttl: P1M

    - !group clients

    # Allow hosts in the `clients` group to be signed
    - !permit
      role: !group clients
      privilege: [ sign ]
      resource: !webservice
```
</p>
</details>

### Signing Server x.509 Certificates

Once a x.509 CA is configured in Conjur and a `host` has `sign` privileges,
then the host may submit a CSR to the CA endpoint for signing:

- The host first needs to generate its own private key and a
  certificate signing request (CSR).

- The host must be authenticated to conjur, and then POST the PEM
  encoded CSR to `/ca/<account>/<ca_id>/certificate`

- If the CSR is valid and the host is authorized, then the CA
  will respond with the PEM encoded, signed certificate.
  
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

## Signing Client SSH Certificates

Once a SSH CA is configure in Conjur and a `user` has `sign` privileges,
the the user may submit a CSR to the CA endpoint for signing:

- The user first needs to generate their own SSH private key and public
  key.

- The user must be authenticated to conjur, and then POST the OpenSSH
  encoded public key to `/ca/<account>/<ca_id>/certificate?kind=ssh`.

- If the request is valid and the user is authorized, then the CA
  will respond with the OpenSSH encoded, signed certificate.

- In the alpha, the SSH certificates are created with `permit-pty` and
  no other certificate extensions.
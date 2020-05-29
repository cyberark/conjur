# Solution Design - Variable Provisioning

## Problem Definition

The lifecycle of a secret value in Conjur suffers from a couple of shortcomings
that make it less effective than it could be. These include:

1. **Browsing-up**: Secret values are often generated on a less-trusted, or
   less-secure platform than Conjur itself, and then loaded into the more-secure
   platform.

2. **Domain Knowledge**: Secret values for access often require a degree of
   domain knowledge to create and configure (e.g. x509 certificates, OAuth tokens)
   which can lead to accidental misconfigurations or malformed values.

3. **Provenance**: By only storing values produced outside of Conjur, the
   audit information around secrets lack key provenance information regarding
   their creation and attributes.

Variable Provisioning is feature proposal to address these shortcomings by allowing
Conjur to produce secret values internally, based on variable annotations defined
in Conjur policy.

## Table of Contents

- [Glossary](#glossary)
- [Useful links](#useful-links)
- [Background](#background)
- [Issue description](#issue-description)
  * ['Browsing-up` for secrets management](#-browsing-up--for-secrets-management)
  * [Secrets Domain Knowledge Required](#secrets-domain-knowledge-required)
  * [Human Intervention Required](#human-intervention-required)
  * [Credential Provenance](#credential-provenance)
- [Solution](#solution)
  * [Design](#design)
  * [Backwards compatibility](#backwards-compatibility)
  * [Performance](#performance)
  * [Affected Components](#affected-components)
- [Security](#security)
- [Test Plan](#test-plan)
- [Logs](#logs)
  * [Audit](#audit)
- [Documentation](#documentation)
- [Version update](#version-update)
- [Open questions](#open-questions)
- [Breaking](#breaking)

## Background

The purpose of Variables in Conjur is to put values in them for applications to
use for service access. These values often consist of:

- Passwords
- API Keys
- x509 Private Keys
- x509 Certificates

The typical workflow for a Variable is:

- The Variable is created when it is defined in a Conjur policy document and loaded
  into Conjur:

  ```YAML
  # my-variable.yaml

  - !variable my-api-key
  ```

  ```sh-session
  $ conjur policy load root my-variable.yaml
  ...
  ```

- The owner of the value uses the Conjur API or CLI to store the value in the Variable:
  
  ```sh-session
  $ conjur variable values add my-api-key abcdef12345
  ...
  ```

- Once stored, access to the variable may be granted to applications, and those
  applications can use value using the Conjur API, Summon, Secretless, etc.

## Issue description

There are a couple of issues this solution intends to address:

### 'Browsing-up` for secrets management

"Browse-up" is defined as [[ref]](https://www.ncsc.gov.uk/whitepaper/security-architecture-anti-patterns#section_3):

> When administration of a system is performed from a device which is less trusted
> than the system being administered.

Unless performed only on dedicated, controlled workspaces, the `variable values add`
step in our existing workflow necessitates that all secrets stored in Conjur (a
"trusted system") must first travel through a user's workstation (a "less trusted system").

### Secrets Domain Knowledge Required

This isn't an "issue" as much as an opportunity for added value. Conjur today serves
essentially as a database with encryption and audit. While these are crucial, as
a Secrets store and Access Control system, there is an opportunity to provide more
access control domain knowledge in Conjur itself, rather than requiring this as
pre-requisite knowledge a user needs.

An example of this is X.509 Certificates used for authentication, secure communications,
and data integrity. While it may be simple enough to understand why I would want
to use Certificates in my applications and infrastructure. Creating and maintaining
these certificates, and a public key infastructure (PKI) is
[anything but trivial](https://smallstep.com/blog/everything-pki/). And mistakes
here can invalidate the security gains from using certificates in the first place.

### Human Intervention Required

As application deployments scale up, the need to automate the creation and rotation
of credentials will continue to grow as human provisioning of credentails becomes
a bottleneck. Our API enables end-users to bolt this automation onto Conjur, but
we have an opportunity to enable more just-in-time creation of these credentails
on behalf the user to make this kind of automation more widely available.

### Credential Provenance

While the information in Conjur is useful for auditing the *use* of a credential,
Conjur is missing any ability to audit the *provenance* of a credential or its current
validity.

## Solution

The solution I propose to address these issues is **variable provisioning**, in which
Conjur is configured (through the policy where a variable is defined) to provision
the secret value for a variable when the policy for that variable is loaded.

For example, defining a variable to store an RSA private key could be represented
in policy as:

```yaml
- !variable
  id: private-key
  annotations:
    provision/provisioner: rsa
    provision/rsa/length: 2048
```

With X.509 in particular, variable provisioning can be use to provide certificate
signing services managed and trackable entirely within policy. For example, to
define a root CA in Conjur would be as simple as the following policy. Because
the properties of the certificate are defined in annotations, it becomes simple
to inspect the provenance of the certificate value stored in this variable.

```yaml
- !variable
  id: private-key
  annotations:
    provision/provisioner: rsa
    provision/rsa/length: 2048

- !variable
  id: certificate
  annotations:
    provision/provisioner: x509-certificate
    provision/x509-certificate/subject/cn: conjur-master-ca
    provision/x509-certificate/subject/c: US
    provision/x509-certificate/basic-constraints/ca: true
    provision/x509-certificate/basic-constraints/critical: true
    provision/x509-certificate/key-usage/critical: true
    provision/x509-certificate/key-usage/key-cert-sign: true
    provision/x509-certificate/key-usage/crl-sign: true
    provision/x509-certificate/private-key/variable: ca/private-key
    provision/x509-certificate/issuer/private-key/variable: ca/private-key # Self-signed CA
    provision/x509-certificate/issuer/certificate/self: true
    provision/x509-certificate/ttl: P1Y
```

This CA can then be used to issue server certificates using variable provisioning:

```yaml
- !host

- !variable
  id: private-key
  owner: !host
  annotations:
    provision/provisioner: rsa
    provision/rsa/length: 2048

- !variable
  id: certificate
  owner: !host
  annotations:
    provision/provisioner: x509-certificate
    provision/x509-certificate/subject/cn: my-server
    provision/x509-certificate/subject/c: US
    provision/x509-certificate/basic-constraints/critical: true
    provision/x509-certificate/key-usage/critical: true
    provision/x509-certificate/key-usage/key-encipherment: true
    provision/x509-certificate/private-key/variable: servers/my-server/private-key
    provision/x509-certificate/issuer/private-key/variable: ca/private-key
    provision/x509-certificate/issuer/certificate/variable: ca/certificate
    provision/x509-certificate/ttl: P30D
```

An example of variable provisioning for just-in-time secrets to provision
database access credentials on-demand:

```yaml
- !variable
  id: db-username
  owner: !host
  annotations:
    provision/provisioner: random
    provision/random/length: 8
    provision/random/charset: A-Za-z0-9
    provision/random/template: db-user-{}

- !variable
  id: db-password
  owner: !host
  annotations:
    provision/provisioner: postgresql
    provision/postgresql/role/name/variable: apps/my-app/db-username
    provision/postgresql/role/ttl: P30D
    provision/postgresql/provisioner/username/variable-id: ops/postgres/provisioner/username
    provision/postgresql/provisioner/password/variable-id: ops/postgres/provisioner/password
```

### Design
[//]: # (Add any diagrams, charts and explanations about the design aspect of the solution. Elaborate also about what the expected user experience for the feature)

- Pluggable, similar to authenticators

> TBD

### Backwards compatibility
[//]: # (Address how you are going to handle backwards compatibility, if necessary)

> TBD

### Performance
[//]: # (Elaborate on whether your solution will affect the product's performance, and how)

> TBD

### Affected Components
[//]: # (Address the componentes that will be affected by your solution [Conjur, DAP, etc.])

> TBD

## Security
[//]: # (Are there any security issues with your solution? Even if you mentioned them somewhere in the doc it may be convenient for the security architect review to have them centralized here)

> TBD

## Test Plan
[//]: # (Fill in the table below to depict the tests that should run to validate your solution)
[//]: # (You can use this tool to generate a table - https://www.tablesgenerator.com/markdown_tables#)

> TBD

| **Title** | **Given** | **When** | **Then** | **Comment** |
|-----------|-----------|----------|----------|-------------|
|           |           |          |          |             |
|           |           |          |          |             |

## Logs
[//]: # (Fill in the table below to depict the log messages that can enhance the supportability of your solution)
[//]: # (You can use this tool to generate a table - https://www.tablesgenerator.com/markdown_tables#)

> TBD

| **Scenario** | **Log message** |
|--------------|-----------------|
|              |                 |
|              |                 |

### Audit 
[//]: # (Does this solution require additional audit messages?)

> TBD

## Documentation
[//]: # (Add notes on what should be documented in this solution. Elaborate on where this should be documented. If the change is in open-source projects, we may need to update the docs in github too. If it's in Conjur and/or DAP mention which products are affected by it)

> TBD

## Version update
[//]: # (Does this solution require a version update? if so, add a list of the projects that should be bumped)

> TBD

## Open questions
[//]: # (Add any question that is still open. It makes it easier for the reader to have the open questions accumulated here istead of them being acattered along the doc)

> TBD

## Breaking
[//]: # (Break the solution into tasks)

> TBD

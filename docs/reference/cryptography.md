---
title: Reference - Cryptography
layout: page
section: reference
description: Conjur Reference - Cryptography
---

Conjur uses industry-standard cryptography to protect your data.

There are several ways in which Conjur uses cryptography, each of which are described below. Much of Conjur's cryptography is implemented in the open-source project [slosilo](https://github.com/cyberark/slosilo). Slosilo is basically a wrapper around OpenSSL.

## Cryptographic audit

Conjur's cryptography has been professionally audited. We responded to all audit findings
with the release of Slosilo 2.0 in November of 2014.

## Authentication tokens

Most requests to Conjur require an authentication token. An authentication token is a Conjur-specific [JWT](https://tools.ietf.org/html/rfc7519) with the following claims:

* **sub** The client's login name.
* **iat** Numeric timestamp at which the token was issued
* **exp** (optional) Numeric timestamp at which the token will expire.
* **cidr** (optional) List of IP netmasks which the request bearing this token must match.

Protected JWS header should also include:

* **alg** Signature algorithm; only `conjur.org/slosilo/v2` is accepted -- see [slosilo](https://github.com/conjurinc/slosilo) for reference implementation.
* **kid** Fingerprint of the token-signing key.

Conjur access tokens are valid for 8 minutes since `iat` if an `exp` claim does not dictate otherwise.

The signature algorithm and access token implementation was included in the cryptographic audit of Conjur v4; since v4 used proprietary JSON token encapsulation which predated JWT, with v5 Conjur migrated to using industry-standard JWT. The signature algorithm and most of the token handling code have been unchanged.

## Secret values

Secrets and API keys are encrypted with AES-256-GCM and stored securely in the following manner:

* The Conjur service has a unique 256-bit master key (don't lose this!).
* Each value is encrypted with a unique encryption key.
* The unique key is encrypted with the master key.
* The encrypted unique key and the encrypted value are stored in the database.

Encryption and decryption of secret values was included in the cryptographic audit.

## Passwords

Passwords are stored in the Conjur database using [bcrypt](https://en.wikipedia.org/wiki/Bcrypt), with a work factor of 12.

Storage and verification of passwords was included in the cryptographic audit.

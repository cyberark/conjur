---
title: Reference - Cryptography
layout: page
---

Conjur uses industry-standard cryptography to protect your data.

There are several ways in which Conjur uses cryptography, each of which are described below. Much of Conjur's cryptography is implemented in the open-source project [slosilo](https://github.com/cyberark/slosilo). Slosilo is basically a wrapper around OpenSSL.

## Cryptographic audit

Conjur's cryptography has been professionally audited. We responded to all audit findings
with the release of Slosilo 2.0 in November of 2014.

## Authentication tokens

Most requests to Conjur require an authentication token. An authentication token is a JSON object which contains the following fields:

* **data** The client's login name.
* **timestamp** The date and time at which the token was issued.
* **signature** HMAC of the token using SHA-256.
* **key** Signature of the token-signing key (used to accelerate token-signing key lookup).

Conjur access tokens are valid for 8 minutes. The lifespan is not configurable.

The access token implementation was included in the [slosilo](https://github.com/cyberark/slosilo) cryptographic audit.

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

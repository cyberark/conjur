# v3.0.1

 * The symmetric cipher class now encrypts and decrypts in a thread-safe manner.
   [cyberark/slosilo#31](https://github.com/cyberark/slosilo/pull/31)

# v3.0.0

* Transition to Ruby 3. Consuming projects based on Ruby 2 shall use slosilo V2.X.X.

# v2.2.2

* Add rake task `slosilo:recalculate_fingerprints` which rehashes the fingerprints in the keystore.
**Note**: After migrating the slosilo keystore, run the above rake task to ensure the fingerprints are correctly hashed.

# v2.2.1

* Use SHA256 algorithm instead of MD5 for public key fingerprints.

# v2.1.1

* Add support for JWT-formatted tokens, with arbitrary expiration.

# v2.0.1

* Fixes a bug that occurs when signing tokens containing Unicode data

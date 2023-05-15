**This Gem has been moved into Conjur. All Conjur Rack Changelog entries should
appear in the main Changelog.**

# unreleased version

# v5.0.0

* Support Ruby 3.
* Bump `slosilo` to v3.0 with ruby 3.
* Remove pinned `bundler` version, use default system bundler.

# v4.2.0

* Bump `slosilo` to v2.2 in order to be FIPS compliant

# v4.0.0

* Bump `rack` to v2, `bundler` to v1.16 in gemspec
* Add Jenkinsfile to project
* Ignore headers such as Conjur-Privilege or Conjur-Audit if they're not
supported by the API (instead of erroring out).

# v3.1.0

* Support for JWT Slosilo tokens.

# v3.0.0.pre

* Initial support for Conjur 5.

# v2.3.0

* Add TRUSTED_PROXIES support

# v2.2.0

* resolve 'own' token to CONJUR_ACCOUNT env var
* add #optional paths to Conjur::Rack authenticator

# v2.1.0

* Add handling for `Conjur-Audit-Roles` and `Conjur-Audit-Resources`

# v2.0.0

* Change `global_sudo?` to `global_elevate?`

# v1.4.0

* Add `validated_global_privilege` helper function to get the global privilege, if any, which has been submitted with the request and verified by the Conjur server.

# v1.3.0

* Add handling for `X-Forwarded-For` and `X-Conjur-Privilege`

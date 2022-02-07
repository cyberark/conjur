**This Gem has been moved into Conjur.  All Policy Parser Changelog entries should
appear in the main Changelog.**

# Unreleased
* Allow the usage of relative paths on revoke and deny policies.
* Return validation error when `restricted_to` values are not correct CIDR
  notated IP addresses or ranges.
  [cyberark/conjur-policy-parser#27](https://github.com/cyberark/conjur-policy-parser/issues/27)
* Return validation error when `restricted_to` values include address bits to the
  right of the provided netmask, or if the CIDR is not IPv4.
  [cyberark/conjur-policy-parser#30](https://github.com/cyberark/conjur-policy-parser/issues/30)
* Upgrade to Ruby V3.

# v3.0.4
* Throw an error when a policy has duplicate members on a resource

# v3.0.3
* Allow annotations to be set on a policy resource.

# v3.0.2

* Fix handling of multiple subjects in a single record.

# v3.0.1

* Fix handling of absolute user ids.

# v3.0.0

* Nextgen-compatible parser.

# v2.2.0

* Add deletion statements `delete`, `deny`, and `revoke`.

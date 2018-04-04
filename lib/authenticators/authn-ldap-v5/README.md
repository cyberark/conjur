# General

This is an LDAP authenticator.  It adds support for logging into Conjur using
an existing LDAP server.  

The service adds a single endpoint:

    POST '/users/:login/authenticate'

where `:login` is the LDAP username, and the body of the request contains the
LDAP password in plain text.

A successful request will return a valid Conjur authentication token.

An unsuccessful request will return a 401 status.

**IMPORTANT NOTE** The Conjur authentication token will be returned for all
valid LDAP credentials, _whether or not the LDAP username exists in Conjur_.
If the user does not exist in Conjur, the token will be effectively useless,
since it will provide no permissions, so there is no security risk.

# Development and Testing

To start developing, simply run:

    ./bin/develop

and wait for the containers to start up.  Then:

    ./bin/develop -t

will run all the tests.  Code changes will auto-reload, and you run the tests
again.  You can also run just the rspec tests, just the cucumber tests, a
single cucumber suite, or a single cucumber test.  For all options see:

    ./bin/develop --help

If you're running only the rspec tests, you can save a second or two by running
them directly on your host:

    bundle exec rspec

# LDAP Configuration

The LDAP server used by the authn-ldap authenticator is configured with
environment variables:

- `LDAP_URI` - for example: ldap://example.com
- `LDAP_BINDDN` and `LDAP_BINDPW` - the binding for search; anonymous if not provided
- `LDAP_BASE` - is the base of the tree,
- `LDAP_FILTER` - with %s as the placeholder for login name; defaults to
`(&(objectClass=posixAccount)(uid=%s))`.

For the test `ldap-server` used in the cucumber tests, these are defined in `docker-compose.yml`.

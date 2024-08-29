# Authn-OIDC Authenticator

## Running Cucumber tests

OIDC Cucumber tests require copying the KeyCloak certificate into the Cucumber
container.  This can be accomplished with the following command:

```sh
ci/oauth/keycloak/fetch_certificate
```

Next, run the Cucumber test(s) as follows:

```sh
KEYCLOAK_CA_CERT=$(cat /etc/ssl/certs/keycloak.pem) bundle exec cucumber -p authenticators_oidc cucumber/authenticators_oidc/features/authn_oidc_v2.feature:100
```

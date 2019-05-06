# Introduction

This doc challenges the current `/authenticators` endpoint in the Conjur API, and
suggests a new approach.

###Terminolgy

|     **Term**    |                       **Description**                       |
|:---------------:|:-------------------------------------------------------------:|
| Conjur Operator | A Conjur user with admin privileges (i.e load to root policy) |

## Current Mechanism

Before we go over the suggestion for the new API, let's understand the flaws of
the current mechanism. Currently, anyone can run an `/authenticators` request 
and will get the following response:
```
{
    "installed": [
        "authn",
        "authn-1",
        "authn-2",
        "authn-3"
    ],
    "configured": [
        "authn",
        "authn-1"
    ],
    "enabled": [
        "authn",
        "authn-1",
        "authn-2"
    ]
}
```

Let's go over the sections in the response to understand them:

1. installed: these authenticators are implemented in conjur code 
(e.g they have an `Authn-somehting::Authenticator` class with a `valid?` method).

2. configured: these authenticators have a webservice called 
`conjur/authn-something/webservice`.

3. enabled: these authenticators are whitelisted in the CONJUR_AUTHENTICATORS variable.

Section 1 has important data but it shouldn't be here, but rather in the docs. It has
nothing to do with the given Conjur instance and just describes the authenticators that
are implemented in Conjur.

Sections 2 & 3 combined can help a conjur user to know if he can use an authenticator
but that's not entirely true. some authenticators need further configuration than 
just configuring a webservice and enabling the authenticator in the ENV (for example, 
authn-oidc needs to load variables). So while a user will get _some_ value using this API, 
it won't fully let him know that he can use the authenticator.

## Feature Overview 

### Use Cases

This feature is divided into 2 personas:

#### Conjur operator

As a Conjur operator\
I'd like to know which authenticators are configured correctly\
So that I can complete the configuration properly if it's incomplete (or remove
it if it's not needed)

#### Conjur user

As a Conjur user\
I'd like to know which authenticators are configured correctly\
So that I can authenticate with a properly configured one

Note that both personas would like to know the same thing but the action they need
it for is different. The Conjur user needs to authenticate according to the response
so this request must be applicable without a Conjur access token. On the other hand 
the Conjur operator needs to know what is needed for completing the configuration,
which may be sensitive data. So he must be authenticated before calling this endpoint.

This leads us to 2 API endpoints:

1. `/authenticators` (for Conjur users)
2. `/authenticators/health` (for Conjur operators)

### Process Logic

In the following example, the authenticators `authn` & `authn-1` are properly configured
and `authn-2` is not whitelisted in the ENV.

#### `/authenticators` Endpoint

- A Conjur user runs an `/authenticators` request:\
`GET /authenticators`
- The user gets a response with code 200 with the following body:\
```
{
   “authenticators”:
   [
      "authn",
      "authn-1"
   ]
}
```

#### `/authenticators/health` Endpoint

- A Conjur operator logs into Conjur (in any authn method) and receives an access token
- The operator runs an `/authenticators/health` request with the given access token:\
`GET /authenticators/health`
- The operator gets a response with code 200 (more info [here](authenticators_health_api.md#Response code for unhealthy authenticators)) with the following body:
```
{
   “authenticators”:
   {
      "authn": "ok",
      "authn-1": "ok",
      "authn-2": "Authentication::Security::NotWhitelisted: CONJ00004E 'authn-2' is not whitelisted in CONJUR_AUTHENTICATORS", 
   },
   "ok": false
}
```
- The operator understands the issue from the response and fixes it
- The operator runs the request once again until he gets a healthy response

### Security

#### `/authenticators` Endpoint

Although the response reveals which authenticators are configured and this request is prone
for brute-force attacks, the value of this endpoint for the user is high and can
provide the information needed for authentication. Furthermore, we don't say _why_
the authenticator is invalid so this endpoint can be hit by anyone,
without the need of a Conjur access token

#### `/authenticators/health` Endpoint

This endpoint reveals some serious details on the Conjur environment, so it should be 
secure. As the use-case of this endpoint is to be hit by the operator who configures an
authenticator, we can limit this request to be run only from `localhost` and only
with a Conjur access token of a privileged user.

Any request lacking a valid access token will be responded with a 403 code.

Note: The term "privileged user" is still under sharpening.

Full feature doc for the `/authenticators/health` Endpoint can be found [here](authenticators_health_api.md)
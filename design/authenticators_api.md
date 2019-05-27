# Introduction

This doc challenges the current `/authenticators` endpoint in the Conjur API, and
suggests a new approach.

Full feature doc for the Authenticator Status API can be found [here](authenticator_status_api.md)

### Personas

|     **Persona**    |                       **Description**                             |
|:---------------:|:-----------------------------------------------------------------:|
| Conjur Operator | A Conjur user with enhanced privileges (loads policies to root, configures authenticators, etc.) |
| Conjur User     | A developer/app that needs to login to Conjur to retrieve secrets |

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

1. configured: these authenticators have a webservice called 
`conjur/authn-something/webservice`.

1. enabled: these authenticators are whitelisted in the CONJUR_AUTHENTICATORS variable.

Section 1 has important data but it shouldn't be here, but rather in the docs. It has
nothing to do with the given Conjur instance and just describes the authenticators that
are implemented in Conjur. 

Sections 2 & 3 combined _can_ help a conjur user to know if he can use an authenticator
but that's not entirely true. some authenticators need further configuration than 
just configuring a webservice and enabling the authenticator in the ENV (for example, 
authn-oidc needs to load variables). So while a user will get _some_ value using this API, 
it won't fully let him know that he can use the authenticator, which is the purpose of this.

## Feature Overview 

### Use Cases

This feature is divided into 2 personas:

#### Conjur operator

**As a** Conjur operator\
**I'd like to** know that an authenticator is configured correctly\
**So that** I can complete the configuration properly if it's incomplete (or remove
it if it's not needed)

#### Conjur user

**As a** Conjur user\
**I'd like to** know which authenticators are available for authentication\
**So that** I can authenticate with a properly configured one

Note that both personas would like to know the same thing (configured correctly == available for authentication)
but the action they need it for is different. 

We can learn 2 things from the above:

1. The Conjur user needs to authenticate according to the response. So this request must be applicable **without** a Conjur access token. 
1. The Conjur operator needs to know which actions are needed for completing the configuration,
which may consist sensitive data. So this request must be applicable **only with** a Conjur access token.

This leads us to 2 API endpoints:

1. `/authenticators` (for Conjur users)
1. `/authenticators/<authenticator_id>/status` (for Conjur operators)

### Process Logic

In the following example, the authenticators `authn` &`authn-1/service-id` are properly configured
and `authn-2` is not whitelisted in the ENV.

#### `/authenticators` Endpoint

- A Conjur user runs an `/authenticators` request:\
`GET /authenticators`
- The user gets a response with code 200 with the following body:
```
{
   “authenticators”:
   [
      "authn",
      "authn-1/service-id"
   ]
}
```

***Note:*** Some of the authenticators have a service-id. If an authenticator has one then it should
be present in the response.

We don't track the implemented (currently called `installed`) authenticators in this API. More info [here](authenticators_api.md#track-implemented-authenticators-in-the-authenticators-endpoint)

#### `/authenticators/<authenticator_id>/status` Endpoint

In the following example, a Conjur Operator configured the authenticator `authn-2/service-id` 
and forgot to enable the authenticator in the ENV. He would like to know if the configuration was successful.

- A Conjur operator logs into Conjur (in any authn method) and receives an access token
- The operator configures the authenticator `authn-2/service-id`
- The operator runs an `/authenticators/<authenticator_id>/status` request with the given access token:\
`GET /authenticators/authn-2/service-id/status`
- The operator gets a response with code 500 (more info [here](authenticator_status_api.md#response-code-for-unhealthy-authenticators)) with the following body:
```
{
  "authn-2/service-id": {
    "status": "error",
    "error": "Authentication::Security::NotWhitelisted",
    "code": "CONJ00004E",
    "message": "'authn-2/service-id' is not whitelisted in CONJUR_AUTHENTICATORS",
  }
}
```
- The operator understands the issue from the response and fixes it
- The operator runs the request once again until he gets a healthy response

#### `/info` endpoint

Another endpoint we should address is `evoke`'s `/info` endpoint, which contains the data of the `/authenticators` endpoint
(with other info such as release, version, etc.). This endpoint calls `http://localhost/authenticators` and adds the output to the info
json. Having the same data in 2 different places is not optimal as it can confuse the user (and developers), so it would make sense to move the
implementation of the `/authenticators` endpoint to `evoke`, and remove the `/authenticators` endpoint.
However, as `evoke` is not part of the OSS, we will leave the implementation in the `/authenticators` endpoint and will not change the implementation in `evoke`.

### Security

#### `/authenticators` Endpoint

Although the response reveals which authenticators are configured and this request is prone
for brute-force attacks, the value of this endpoint for the user is high and can
provide the information needed for authentication. Furthermore, we don't say _why_
the authenticator is invalid (or even mention that an authenticator is invalid) so this endpoint can be hit by anyone,
without the need of a Conjur access token

#### `/authenticators/<authenticator_id>/status` Endpoint

This endpoint reveals some serious details on the Conjur environment, so it should be 
secure. Any request lacking a valid access token will be responded with a 403 code.

As the use-case of this endpoint is to be hit by the operator who configures an
authenticator, we will limit access to this endpoint by defining a webservice on it,
and granting permission on it.

A Conjur Operator will need to load the following policy in order to enable it:
```
- !webservice
  id: conjur/authenticators/<authenticator_id>/status
  
- !permit
  role: !group operators
  privilege: [ read, authenticate ]
  resource: !webservice conjur/authenticators/<authenticator_id>/status
```

In case such a policy is loaded then access to this endpoint will be available, and
will be restricted only to users who are members of the `operators` group. 

In case the policy above is not loaded then the endpoint will return a 403 Forbidden response to any request.

# Appendix
## Lines of Thought

### Track implemented authenticators in the `/authenticators` endpoint

TODO: add content

---

Full feature doc for the `/authenticators/<authenticator_id>/status` Endpoint can be found [here](authenticator_status_api.md)
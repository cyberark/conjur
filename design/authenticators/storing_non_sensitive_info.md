# Store Authenticators non-sensitive information

- [Store Authenticators non-sensitive information](#store-authenticators-non-sensitive-information)
  * [Introduction](#introduction)
  * [Solution](#solution)
    + [Authenticator modification](#authenticator-modification)
    + [Backwards compatibility](#backwards-compatibility)
  * [Test plan](#test-plan)
  * [Performance](#performance)
    + [Configuration](#configuration)
    + [Authentication](#authentication)
  * [Security](#security)
  * [Documentation](#documentation)
  * [Version Update](#version-update)
  * [Delivery Plan](#delivery-plan)
  
## Introduction

In several authenticators we need to store some information for their
authentication process. For example, in `authn-oidc` we have 2 variables
that store this kind of data:
  - provider-uri
  - id-token-user-property
  
These 2 variables are defined in the authenticator policy and are loaded with
values before users can authenticate with the authenticator. However, this data
is not sensitive and was stored in variables just because we didn't think of a 
better solution. As the data is not sensitive, it makes sense to store them in
other methods than in variables, which can improve the UX of the authenticator
configuration and make another simplicity step.

## Solution

The suggested solution is to store this data in the authenticator webservice's
annotations. 

For example, let's look at a policy that defines an `authn-oidc`
authenticator:

```
- !policy
  id: conjur/authn-oidc/keycloak
  body:
  - !webservice
    annotations:
      description: Authentication service for Keycloak, based on Open ID Connect.

  - !variable
    id: provider-uri

  - !variable
    id: id-token-user-property

  - !group
    id: users
    annotations:
      description: Group of users who can authenticate using the authn-oidc/keycloak authenticator

  - !permit
    role: !group users
    privilege: [ read, authenticate ]
    resource: !webservice
```

After loading the policy above, the operator will load the variables with values:
```
conjur variable values add conjur/authn-oidc/keycloak/provider-uri "some-provider-uri"
conjur variable values add conjur/authn-oidc/keycloak/id-token-user-property "some-property"
```

In the suggested approach, the policy will not have variables, and will be defined
as follows:
```
- !policy
  id: conjur/authn-oidc/keycloak
  body:
  - !webservice
    annotations:
      description: Authentication service for Keycloak, based on Open ID Connect.
      provider-uri: some-provider-uri
      id-token-user-property: some-property

  - !group
    id: users
    annotations:
      description: Group of users who can authenticate using the authn-oidc/keycloak authenticator

  - !permit
    role: !group users
    privilege: [ read, authenticate ]
    resource: !webservice
```

This improves the UX of the authenticator configuration for the following reasons:
  - The user doesn't need to load values into each variable so we have fewer steps
    of authenticator configuration.
  - The policy shows clearly all the data of the authenticator, comparing to
    the current policy where the data of the variables is not visible.

### Authenticator modification

What happens if the user configured an authenticator, and then needs to replace
one of the non-sensitive data objects? In this case, the user will need to reload
the policy with the `--delete` flag. 

For example, let's look at the following scenario. At first, the policy tree
is empty:
```
root@daf912c19ac3:/# conjur list
[
  "myConjurAccount:policy:root"
]
```

Then I load the policy:
```
- !policy
  id: some-policy
  body:
  - !webservice
    annotations:
      annotation-key: annotation-value

  - !variable some-variable
```

with `conjur policy load root some-policy.yml`. 

When we run `conjur list` we will get:
```
root@daf912c19ac3:/# conjur list
[
  "myConjurAccount:policy:root",
  "myConjurAccount:policy:some-policy",
  "myConjurAccount:webservice:some-policy",
  "myConjurAccount:variable:some-policy/some-variable"
]
```

and when we run `conjur show myConjurAccount:webservice:some-policy` we will get:
```
root@daf912c19ac3:/# conjur show myConjurAccount:webservice:some-policy
{
  "created_at": "2020-04-19T12:16:50.866+00:00",
  "id": "myConjurAccount:webservice:some-policy",
  "owner": "myConjurAccount:policy:some-policy",
  "policy": "myConjurAccount:policy:root",
  "permissions": [

  ],
  "annotations": [
    {
      "name": "annotation-key",
      "value": "annotation-value",
      "policy": "myConjurAccount:policy:root"
    }
  ]
}
```

We can see that the webservice has the annotation `annotation-key` with the value 
`annotation-value`.

Now, for some reason, I decide to replace the value of `annotation-key` to
`some-other-annotation-value`.

All I need to do is change the policy to:
```
- !policy
  id: some-policy
  body:
  - !webservice
    annotations:
      annotation-key: some-other-annotation-value

  - !variable some-variable
```

and load it with `conjur policy load --delete root some-policy.yml`.

Now when we run `conjur list` we will get:
```
root@daf912c19ac3:/# conjur list
[
  "myConjurAccount:policy:root",
  "myConjurAccount:policy:some-policy",
  "myConjurAccount:webservice:some-policy",
  "myConjurAccount:variable:some-policy/some-variable"
]
```

and when we run `conjur show myConjurAccount:webservice:some-policy` we will get:
```
root@daf912c19ac3:/# conjur show myConjurAccount:webservice:some-policy
{
  "created_at": "2020-04-19T12:16:50.866+00:00",
  "id": "myConjurAccount:webservice:some-policy",
  "owner": "myConjurAccount:policy:some-policy",
  "policy": "myConjurAccount:policy:root",
  "permissions": [

  ],
  "annotations": [
    {
      "name": "annotation-key",
      "value": "some-other-annotation-value",
      "policy": "myConjurAccount:policy:root"
    }
  ]
}
```

We can see that the annotation `annotation-key` now has the value 
`some-other-annotation-value`.

Furthermore, if we write the following policy:
```
- !policy
  id: some-policy
  body:
  - !webservice
    annotations:
      annotation-key: yet-another-annotation-value
```

without the variable `some-variable`, and load it using the `--delete` flag,
we can see that the variable is not deleted from the DB:
```
root@daf912c19ac3:/# conjur list
[
  "myConjurAccount:policy:root",
  "myConjurAccount:policy:some-policy",
  "myConjurAccount:webservice:some-policy",
  "myConjurAccount:variable:some-policy/some-variable"
]
```

In conclusion, we can see that we have a method to update authenticators' metadata
when it is stored in annotations.

### Backwards compatibility

We will need to support authentication using variables as well, for `authn-oidc`
and `authn-azure`, to maintain backwards-compatibility. This means that for these
two authenticators we will first look for the values in the annotations and if 
they are not present we will retrieve their secrets from the DB. 

New authenticators can implement only storing non-sensitive data in the webservice's
annotations. 

## Test plan

The following tests should be implemented for `authn-oidc` and `authn-azure`:

| **Scenario**                                | **Given**                                                                                 | **When**                                  | **Then**                                                                                                         |
|---------------------------------------------|-------------------------------------------------------------------------------------------|-------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| Authentication - data stored in annotations | A fully-defined authenticator with non-sensitive data stored in annotations               | I authenticate with a valid host          | <ul><li>The authentication succeeds</li><li>Log shows that we used annotations to retrieve the data</li></ul>                               |
| Authentication - data stored in variables   | A fully-defined authenticator with non-sensitive data stored in variables                 | I authenticate with a valid host          | <ul><li>The authentication succeeds</li><li>Log shows that we used variables to retrieve the data</li></ul>                             |
| Authentication - data is missing            | An authenticator that is defined without one of its non-sensitive data (e.g provider-uri) | I authenticate with a valid host          | <ul><li>The authentication fails with 401</li><li>Log shows the error `RequiredMetadataMissing` and the name of the metadata</li></ul> |
| Status Check - data stored in annotations   | A fully-defined authenticator with non-sensitive data stored in annotations               | I run a Status Check on the authenticator | I get 200 OK                                                                                                     |
| Status Check - data stored in variables     | A fully-defined authenticator with non-sensitive data stored in variables                 | I run a Status Check on the authenticator | I get 200 OK                                                                                                     |
| Status Check - data is missing              | An authenticator that is defined without one of its non-sensitive data (e.g provider-uri) | I run a Status Check on the authenticator | I get 500 Internal Server Error with `RequiredMetadataMissing` and the name of the metadata in the body          |

Notes: 

  - The "missing metadata" tests should be implemented for each metadata object.
    - In `authn-oidc` we will have a test for missing `provider-uri` and a test for missing `id-token-user-property`.
    - In `authn-azure` we will have a test for a missing `provider-uri`.
  - We will change the current `authn-oidc` and `authn-azure` tests to use annotations
    for storing non-sensitive data (as this is now the documented approach).
    In addition to the existing "missing required variables" tests we will add 
    a test that will verify that an
    authenticator can have its non-sensitive data stored in variables.
  - The existing performance tests will indicate if there is a degradation in
    the authentication performance. More info about performance can be found 
    [here](#performance).
    
## Performance

The performance will be affected in 2 stages of the authenticator lifecycle - 
configuration and authentication.

### Configuration

Currently we have an additional call to the DB for each variable that we load 
its value. If the data is stored in annotations then we don't need that call.

In this stage the performance is improved.

### Authentication

Currently we have a call to the DB for each variable that is needed by the 
authenticator. If the data is stored in annotations we will have a call to get
the webservice's annotation instead. The webservice itself is already loaded from
the DB anyway.

In this stage the performance is improved as we have only one call per authentication
request, instead of N calls (where N is the number of variables).

## Security

As the data is not sensitive there is no reason that it should be stored in
Conjur secrets, and they can be stored in annotations.

## Documentation

We will need to update the doc pages of the Azure and OIDC authenticators to 
configure the policies with the data in annotations instead of in variables.

In addition we will need to explain that users can replace metadata using the 
`--delete` flag, as explained [here](#authenticator-modification).

## Version Update

We should update the versions of the following projects:
  - conjur
  - appliance

## Delivery Plan
  
The delivery plan will include the following steps:
  - Modify the Azure and OIDC authenticators to read the required metadata from
    the webservice's annotations, and only if they are not present - read them
    from variables.
    - EE: 4 days
  - Implement tests according to the test plan
    - EE: 4 days  
  - Documentation
    - EE: 2 days
  - Version Update
    - EE: 1 day

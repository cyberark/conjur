# Introduction

This is a design doc for the user story [OIDC authenticator status check](https://github.com/cyberark/conjur/issues/1063) that is part of the epic [Authenticators Status API returns status of a specific authenticator](https://github.com/cyberark/conjur/issues/1062)

# Feature Overview

***As a*** Conjur operator\
***I'd like to*** know that the OIDC authenticator is configured correctly\
***So that*** I can complete the configuration properly if it's incomplete (or remove
it if it's not needed).

This feature lets the person who configures the OIDC authenticator to get an immediate feedback
on the configuration, before any user needs to run an authentication request.

As mentioned in the general status check implementation details, in addition to the general validations,
some of the authenticators will have additional validations based on their specific requirements.  

***Note***: At this time, we will only be implementing the OIDC status check. 
Later implementations of authenticator status checks will be done incrementally. 
Therefore, if the authenticator does not have the status check implemented, then a 503 error will 
be returned. 

# Implementation Details

As mentioned in the general status check implementation details, we will add the following for the 
OIDC status check:

1. A `Status` CommandClass in the structure `Authentication::AuthnOidc::Status`
1. A `status` method to its existing authenticator class (i.e. `Authentication::AuthnOidc::Authenticator`)
which will call the new CommandClass, as follows: 
 
 ```
 def status
   Authentication::AuthnOidc::Status.new.(
     <input for status check>
   )
 end
 ``` 

The new CommandClass `Authentication::AuthnOidc::Status` will consist of a
`call` method that will perform the following checks:

- The following variables exist and have value
    - `provider-uri`
    - `id-token-user-property`
- The group `conjur/authn-oidc/<service-id>/users` exists and has `read` & `authenticate` 
permissions on the webservice
- The OIDC Provider (defined in the `provider-uri` variable) is responsive

## Things we will not check
- Value of `id-token-user-property` is configured correctly
    - How we would check
        - Change http method to POST and send an id token (who's?)
        - Validate that the value of `id-token-user-property` exists in the id token
    - Pros
        - Future `authenticate` requests will not fail on `id-token-user-property` configuration 
        error
    - Cons
        - We lose generalisation of the HTTP request between the OIDC authenticator and the rest (as we changed the method to POST and added an id token as an input).
        - We need an id token as an input. Who's id token? this can add an extra layer of complexity 
    - Decision: We will not validate the `id-token-user-property` value as the cons are 
    stronger than the pros. As we will still log the error, the operator will be able to 
    see the configuration failure and may proceed accordingly. This is relevant for all the 
    checks but this check's price is too high.

# Test Plan

| **Given**                                 | **When**                                                                                           | **Then**                                   | **Status** |
|-------------------------------------------|----------------------------------------------------------------------------------------------------|--------------------------------------------|------------|
| General checks for the authenticator pass | `provider-uri` variable doesn't exist                                                              | I get a 500 Internal Server Error response | [ ]        |
| General checks for the authenticator pass | `id-token-user-property` variable doesn't exist                                                    | I get a 500 Internal Server Error response | [ ]        |
| General checks for the authenticator pass | `conjur/authn-oidc/{service-id}/users` group doesn't exist                                         | I get a 500 Internal Server Error response | [ ]        |
| General checks for the authenticator pass | `conjur/authn-oidc/{service-id}/users` group exists but doesn't have permissions on the webservice | I get a 500 Internal Server Error response | [ ]        |
| General checks for the authenticator pass | OIDC Provider is not responsive                                                                    | I get a 500 Internal Server Error response | [ ]        |

# Effort Estimation

5 Days

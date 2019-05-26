### Personas

|     **Persona**    |                       **Description**                             |
|:---------------:|:-----------------------------------------------------------------:|
| Conjur Operator | A Conjur user with enhanced privileges (loads policies to root, configures authenticators, etc.) |
| Conjur User     | A developer/app that needs to login to Conjur to retrieve secrets |

# Introduction 

## Feature Overview

**As a** Conjur operator\
**I'd like to** know that an authenticator is configured correctly\
**So that** I can complete the configuration properly if it's incomplete (or remove
it if it's not needed).

This feature lets the person who configures an authenticator to get an immediate feedback 
on the configuration, before any user needs to run an authentication request.

For example, the OIDC Authenticator configuration includes whitelisting the authenticator in the CONJUR_AUTHENTICATORS variable:

`CONJUR_AUTHENTICATORS=authn-oidc/adfs,authn`

Let's say the Conjur Operator configured the OIDC Authenticator and forgot to whitelist 
the authenticator in the CONJUR_AUTHENTICATORS variable. Without the Authenticator Status API, 
the first time the user will encounter the error will be in an authentication request. 
A user `alice` will try to authenticate with OIDC and will get a 401 Unauthorized 
response without any description on what happened (the answer will be in the logs which 
are probably inaccessible to her) even if the actual request is ok. The main problem 
here is that the Unauthorized response has nothing to do with the actual request, as 
the problem is not in it. The problem is in the configuration which was made by another 
person in another time. With the Authenticator Status API the person who does the configuration will 
get an immediate feedback on it, and the users that are *using* the authenticators will not 
be unauthorized due to configuration errors.

### Current Mechanism

The current mechanism for understanding that there is a problem in the Authenticator configuration is as follows:

1. The Operator configures the Authenticator according to the docs
1. A user tries to authenticate\
    1. this may be the Operator himself imitating a user to verify the authenticator works in the dev env
1. The user gets a 401 Unauthorized response
    1. There are other response codes possible but configuration issues will be 401
1. The user reports to the operator that there is an issue
    1. This one is tricky as the user might not know who to report this to.
    1. Again, this may be the operator himself
1. The operator looks in the logs (according to the docs) and finds the issue
1. The operator fixes the issue

This can be iterative as there might be several issues. It is possible to assume that in the case 
above, the operator will solve this with the user and will ask him to try to authenticate again and 
if it's still Unauthorized will solve the configuration issues one-by-one. 

### Process Logic

In the following example, a Conjur Operator configured the authenticator `authn-1/service-id` and would like
to know if the configuration was successful. 

1. The Conjur operator logs into Conjur
1. The Conjur operator configures the Authenticator `authn-1/service-id` according to the docs
1. The operator runs the Authenticator Status request: `GET /authenticators/authn-1/service-id/status`
1. The operator gets a response:
    1. In case the authenticator is healthy, a response with code 200 and the following body:
        
        ```
        {
           "authn-1/service-id": {
             "status": "ok"
           }
        }
        ```
    1. In case the authenticators isn't healthy, a response with code 500 (more info [here](authenticator_status_api.md#response-code-for-unhealthy-authenticators)) and the following body:
        ```
        {
          "authn-1/service-id": {
            "status": "error",
            "error": "<configuration_error>",
            "code": "<conjur_error_code>",
            "message": "<conjur_error_message>",
          }
        }
        ```
        
1. In case there is more than one error in the authenticator, only one will be showed.
1. The operator understands the issue from the response and fixes the issue
1. The operator runs the request once again and until he gets a healthy response

**Note**: Authenticators for which we didn't implement the status-check will have the message "status-check-not-implemented". 

For example, if the status-check is not implemented for the authenticator `authn-2` and I run the following request:
`GET /authenticators/authn-2/status`

Then the response will have code 501 Not Implemented with the following body:
```
{
  "authn-2": {
    "status-check-not-implemented"
  }
}
```

### General Analysis

#### Audit 

As the user isn't accessing any resource there is no need to audit in this feature

#### Security

Security aspects of this feature are defined [here](authenticators_api.md#authenticatorsstatus-endpoint-1)

# Appendix
## Lines of Thought

### Response code for unhealthy authenticators

In case of an error we need to return a response code which will best indicate the issue. Let's explore the possibilities and find the best 
response code. 

2xx isn't good as it doesn't indicate there is an error and 3xx is irrelevant as there is no redirection.
A valid option will be to return an error response code (4xx, 5xx). In this case the 500's make more sense as the error here is not in the 
actual request so it's more of a server error that a client error. The possibilities for 5xx responses are:

- 500 Internal Server Error
    - Con: This is very general and we should try to avoid it when possible
- 501 Not Implemented
    - Con: Well, this is actually implemented. 
- 503 Service Unavailable
    - Con: This doesn't really tell the story as the service that we're calling - The Authenticator status service - is actually available. 
- 502 Bad Gateway & 504 Gateway Timeout
    - Irrelevant as this is not a gateway.

Although we'd like not to return 500 when possible i think there is no specific error code which tells the story here so we need to go with the 
general 500 Internal Server Error

Conclusion: return 500 Internal Server Error. 
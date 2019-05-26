### Personas

|     **Persona**    |                       **Description**                             |
|:---------------:|:-----------------------------------------------------------------:|
| Conjur Operator | A Conjur user with enhanced privileges (loads policies to root, configures authenticators, etc.) |
| Conjur User     | A developer/app that needs to login to Conjur to retrieve secrets |

# Introduction 

## Feature Overview

**As a** Conjur operator\
**I'd like to** know which authenticators are configured correctly\
**So that** I can complete the configuration properly if it's incomplete (or remove
it if it's not needed).

This feature lets the person who configures the Authenticator to get an immediate feedback 
on the configuration, before any user needs to run an authentication request.

For example, the OIDC Authenticator configuration includes whitelisting the authenticator in the CONJUR_AUTHENTICATORS variable:

`CONJUR_AUTHENTICATORS=authn-oidc/adfs,authn`

Let's say the Conjur Operator configured the OIDC Authenticator and forgot to whitelist 
the authenticator in the CONJUR_AUTHENTICATORS variable. Without the Healthcheck API, 
the first time the user will encounter the error will be in an authentication request. 
A user `alice` will try to authenticate with OIDC and will get a 401 Unauthorized 
response without any description on what happened (the answer will be in the logs which 
are probably unaccessible to her) even if the actual request is ok. The main problem 
here is that the Unauthorized response has nothing to do with the actual request, as 
the problem is not in it. The problem is in the configuration which was made by another 
person in another time. With the Healthcheck API the person who does the configuration will 
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

1. The Conjur operator logs into Conjur
1. The Conjur operator configures the Authenticators according to the docs
    1. We might have several authenticators configured
1. The operator runs the Healthcheck request: `GET /authenticators/health`
1. The operator gets a response:
    1. In case all the authenticators are healthy, a response with code 200 and the following body:
        
        ```
        {
           “authenticators”:
           {
              "authn-1": "ok",
              "authn-2": "ok"
           },
           "ok": true
        }
        ```
    1. In case some of the authenticators aren't healthy, a response with code 500 (more info [here](authenticators_health_api.md#response-code-for-unhealthy-authenticators)) and the following body:

        ```
        {
           “authenticators”:
           {
              "authn-1": "ok",
              "authn-2": "<configuration error>",
           },
           "ok": false
        }
        ```
        1. In case there is more than one error in an authenticator, they should be comma-separated.
1. The operator understands the issue from the response and fixes the issue
1. The operator runs the request once again and until he gets a healthy response

**Note**: we should list in the response all the authenticators which are implemented in Conjur. 
Authenticators for which we didn't implement the health-check will have the message "health-check-not-implemented". 
A possible response can look like this:
```
{
   "authenticators":
   {
      "authn": {
        "status": "ok"
      },
      "authn-1/service-id": {
        "status": "ok"
      },
      "authn-2": {
              "health-check-not-implemented"
      },
      "authn-3": {
        "status": "error",
        "error": "Authentication::Security::NotWhitelisted",
        "code": "CONJ00004E",
        "message": "'authn-3' is not whitelisted in CONJUR_AUTHENTICATORS",
      }
   },
   "ok": false
}
```

More info on this can be found in the appendix 
[here](authenticators_health_api.md#which-authenticators-should-we-list-in-the-response) 
& [here](authenticators_health_api.md#incremental-health-check-for-authenticators).

### General Analysis

#### Audit 

As the user isn't accessing any resource there is no need to audit in this feature

#### Security

Security aspects of this feature are defined [here](authenticators_api.md#authenticatorshealth-endpoint-1)

# Appendix
## Lines of Thought

### Which authenticators should we list in the response

When running the List Authenticators request
`GET /authenticators`

We get the following response:
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
        "authn-1/service-id"
    ],
    "enabled": [
        "authn",
        "authn-1/service-id"
    ]
}
```

Let's go over the sections and decide which group should be the one we list in the response and 
check their health.

##### Installed
The "installed" authenticators are those who meet to following criteria:

- Its class name is "Authenticator"
- Its parent module starts with "Authn"
- It has the "valid?" method

##### Configured
The "configured" authenticators are those who have a webservice resource starting with "conjur/authn-". 

This group is not the one we want to list in the health-check as in case there is an error with loading the policy then the authenticator will not be configured and then we won't test it

##### Enabled
The "enabled" authenticators are those who are whitelisted in the CONJUR_AUTHENTICATORS variable. If the variable is not configured then we have only the "authn" authenticator.

##### Conclusion
It seems that we'll want to list all the "installed" authenticators and test if they are healthy.

Note: At this point the "authn-oidc" is not showing in the installed authenticators as it doesn't meet 
the first & third sections in the criteria. we'll need to fix this before implementing this.

### Incremental health check for authenticators

As each authenticator health check will need its own development effort, we'll want to have this feature in production even if we didn't perform the needed development for each authenticator. This means that we need some "N/A" status for authenticators which we didn't develop their health-check.

So the statuses for authenticators are:

- ok: the authenticator is healthy
- fail: the authenticator is unhealthy
- health-check-not-implemented: he authenticator health-check is not implemented

So a response can look like this:
```
{
   “authenticators”:
   {
      "authn-ldap": "health-check-not-implemented",
      "authn-oidc/okta": "error",
      "authn": "ok"
   },
   "ok": false
}
```

Another option is to not have the authenticator health-check in the response at all in case it's not implemented. so for the case above, the response will be:
```
{
   “authenticators”:
   {
      "authn-oidc/okta": "error",
      "authn": "ok"
   },
   "ok": false
}
```

I think the first option is better as it tells the full story explicitly without leaving the user with questions.

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
    - Con: This doesn't really tell the story as the service that we're calling - The Authenticator health service - is actually available. 
- 502 Bad Gateway & 504 Gateway Timeout
    - Irrelevant as this is not a gateway.

Although we'd like not to return 500 when possible i think there is no specific error code which tells the story here so we need to go with the 
general 500 Internal Server Error

Conclusion: return 500 Internal Server Error. 


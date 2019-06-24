# Feature Overview

***As a*** Conjur operator\
***I'd like to*** know that an authenticator is configured correctly\
***So that*** I can complete the configuration properly if it's incomplete (or remove
it if it's not needed).

This feature lets the person who configures an authenticator to get an immediate feedback
on the configuration, before any user needs to run an authentication request.

# Implementation Details

We will create a new route in `routes.rb` for `/authenticators/:authenticator(/:service_id)/:account/status`.
This route will lead to `authenticate_controller` which will consist of a new `status` method.
In this method we will call a new CommandClass `Authentication::Status`. This class's
`call` method will perform the following checks:

- The requesting user has access to the authenticator status route webservice
    - more info in the Security section of the [epic](https://github.com/cyberark/conjur/issues/1062)
- The authenticator is implemented
- The account exists
    - although a wrong account in an `/authenticate` request will indicate a client error and
    not a server error, we still need to verify it exists in order to verify that the webservice exists
    under that account
- The webservice exists
- The authenticator is enabled in the ENV
- Specific authenticator requirements
    - Some authenticators need extra validation. The status check should verify 
    the requirements of the given authenticator. As mentioned in the Epic, if 
    the method is not implemented in the authenticator we will return a 503 Not 
    Implemented response. We will do this by adding a `valid?` 
 
 ***Note:*** The default authenticator (`authn`) is always healthy
 
 # Test Plan
 
 # Effort Estimation
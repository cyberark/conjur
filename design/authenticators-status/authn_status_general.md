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
 
 ## Implementing Specific authenticator status check
 
 ***Note:*** In the following section, we will use `authn-oidc` as an example.
 
 For each authenticator that will implement the status check, we will add:
 1. A `Status` CommandClass in the structure `Authentication::AuthnOidc::Status` (its body is described [here]()). 
 1. A `status` method to its authenticator class (i.e. `Authentication::AuthnOidc::Authenticator`)
 which will call the new CommandClass, as follows: 
 
 ```
 def status
   Authentication::AuthnOidc::Status.new.(
     <input for status check>
   )
 end
 ``` 
 
 The `status` method above will be called from the general status check, when validating
 the authenticator's specific requirements. We will first verify that the `status` method exists
 in the `Authenticator` class, which will indicate that the status check is implemented on the given
 authenticator. Therefore, the `call` method of the general status check 
 will look like the following:
                                                                            
 ```
 def call
  validate_authenticator_exists
  validate_authenticator_implements_status_check
  .
  .
  # perform general validations (whitelisted in env, etc.)
  .
  .
  validate_authenticator_requirements
 end
 
 private
 
 def validate_authenticator_exists
   raise Err::AuthenticatorNotFound unless authenticator
 end
     
 def validate_authenticator_implements_status_check
  unless authenticator.method_defined?(:status)
    raise 503
 end
 
 def validate_authenticator_requirements
  authenticator.status
 end
 
 def authenticator
  # The `@authenticators` map includes all authenticator classes that are implemented in 
  # Conjur (`Authentication::AuthnOidc::Authenticator`, `Authentication::AuthnLdap::Authenticator`, etc.). 
  #
  @authenticator = @authenticators[@authenticator_input.authenticator_name]
 end
 ```
 
 # Test Plan
 
 # Effort Estimation
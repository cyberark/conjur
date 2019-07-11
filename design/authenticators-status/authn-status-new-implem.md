# Implementing Authenticator Status Checks
The authenticator status check allows operators to check if the authenticator is configured correctly. With this capability, 
operators can make a RESTful request using the Conjur API and receive a response identifying if configuration was successful.
If not, the operators receive the proper error identifying the step of failure. 
The first authenticator to utilize this feature is Authn OpenID Connect. 

_For a complete status check flow [diagram](https://github.com/cyberark/conjur/blob/master/design/authenticators-status/authn-status-flow.jpeg)_

This doc describes how to expand the status check functionality to other authenticators.
For each authenticator, a suite of [general](https://github.com/cyberark/conjur/blob/master/design/authenticators-status/authn_status_general.md) 
checks are run followed by those specific to the authenticator.  

General checks include:
1. The requesting user has access to the authenticator status route webservice
1. _The authenticator implements the status check_
1. The account exists
1. The webservice exists
1. The authenticator is enabled in the ENV
1. _Checks specific for the new authenticator_

To properly implement the status check functionality for the new authenticator, you will need to expand on italicized checks 2 and 6. 
As described in step 2, the status of an authenticator method is checked for implementation. Therefore, you will need to 
create a new class in the structure of Authentication::<New_Authenticator>::Authenticator and add a status method like so:

```ruby
def status(account:, authenticator_name:, webservice:)
  Authentication::<New_Authenticator>::ValidateStatus.new.(
    account: account,
      service_id: webservice.service_id
  )
end
```

This status method will call the ValidateStatus’s CommandClass and run the new authenticator-specific checks as described in step 6. This new 
ValidateStatus CommandClass should be in the structure of Authentication::<New_Authenticator>::ValidateStatus and will be need to be in a format similar to:

```ruby
module Authentication
  module New_Authenticator

    Err = Errors::Authentication::New_Authenticator
    # Possible Errors Raised:
      
    ValidateStatus = CommandClass.new(
      dependencies: {
      },
      inputs: %i()
    ) do

def call
  specific_authn_check
 .
 .
 .
end

private
```

## Test Plan
All new status check implementations should inspire a new suite of unit and integration tests appropriate for that authenticator.
The response from each test should be consistent with previous status check implementations. For example:

A successful response:
```json
{
  "status": "ok"
}
```

A failure:
```json
{
  "status": "error",
  "error": "<configuration_error>"
}
```

An example of an error response resulting from an incorrect configuration of the authenticator:
```json
{
  "status": "error",
  "error": "#<Errors::Authentication::AuthenticatorNotFound: CONJ00001E Authenticator 'New_Authenticator' is not implemented in Conjur>"
}
```
***NOTE:*** All new errors should be placed in the `error.rb` and be referenced in the tests as displayed above.
# Implementing Authenticator Status API
The authenticator status API allows operators to get immediate feedback on the authenticator configuration. Once the configuration of an authenticator is complete, the operator sends a status request and the status of the given authenticator is returned. 

If the configuration was successful, the response received will reflect this. If not, an error will be provided in the response, identifying the step of failure.

The first authenticator to utilize this feature is Authn OpenID Connect. For more information about the design behind the Status API and implementation details see the [Status epic](https://github.com/cyberark/conjur/issues/1062). 
It is advised that you read the epic before expanding status to other authenticators.

_For a complete status flow [diagram](https://github.com/cyberark/conjur/blob/master/design/authenticators-status/authn-status-flow.jpeg)_

This doc describes how to expand the status functionality to other authenticators.
For each authenticator, a suite of [general](https://github.com/cyberark/conjur/blob/master/design/authenticators-status/authn_status_general.md) 
checks are run followed by those specific to the authenticator.  

General checks are outlined below and steps that require developer intervention to implement and enable status for authenticators are italicized accordingly.
1. The requesting user has access to the authenticator status webservice
    1. See the security section [here](https://github.com/cyberark/conjur/issues/1062) for more info about this webservice 
1. _The authenticator implements the status method_
1. The account exists
1. The webservice exists
1. The authenticator is enabled in the ENV
1. _Checks specific requirements for the new authenticator_

To properly implement the status functionality in the new authenticator, you will need to expand on italicized checks 2 and 6. 
As described in step 2, the status of an authenticator method is checked for implementation. Therefore, you will need to add a status method to the Authenticator class (`Authentication::Authn<Type>::Authenticator`) like so:

```ruby
def status(authenticator_status_input:)
  Authentication::Authn<Type>::ValidateStatus.new.call(
    <ValidateStatus input>
  )
end
```

**NOTE:** It is important to keep the `Authn<Type>` pattern when defining the class structure. 

The `authenticator_status_input` object wraps a group of fields that may be needed by authenticators to perform their configuration checks. Each authenticator may require different variations of the provided fields.

The fields in the `authenticator_status_input` object include:

`authenticator_name`- type of authenticator, for example authn-oidc

`service_id`- ID of the authenticator provider, for example Okta

`account`- name of organization

`username`- name of the user who sent the status request

`webservice`- resource for the authenticator

`status_webservice`- resource for the authenticator's status endpoint

See below for an example of the [status implementation](https://github.com/cyberark/conjur/blob/master/app/domain/authentication/authn_oidc/authenticator.rb#L12) for OIDC. Notice how this particular status implementation uses only the `account` and `service_id` fields from the `authenticator_status_input` object.
 
```ruby
def status(authenticator_status_input:)
    Authentication::AuthnOidc::ValidateStatus.new.call(
      account: authenticator_status_input.account,
        service_id: authenticator_status_input.service_id
    )
    end
end
```

This status method will call the ValidateStatus’s CommandClass and run the new authenticator-specific checks as described in step 6. This new 
ValidateStatus CommandClass should be in the structure of `Authentication::Authn<Type>::ValidateStatus` and will need to be in a format similar to:

```ruby
module Authentication
  module Authn<Type>

    Err = Errors::Authentication::Authn<Type>
    # Possible Errors Raised:
      
    ValidateStatus = CommandClass.new(
      dependencies: {
      },
      inputs: %i()
    ) do
    
        def call
          specific_authn_check1
          specific_authn_check2
          .
          .
        end
    
        private
        
        def specific_authn_check1 
        end
    
        def specific_authn_check2
        end
      end
   end
end
```

**NOTE:** It is important to keep the `Authn<Type>` pattern when defining the class structure. 

**NOTE:** For an example of an Authenticator ValidateStatus CommandClass see [here](https://github.com/cyberark/conjur/blob/master/app/domain/authentication/authn_oidc/validate_status.rb)

## Test Plan
All new status implementations should inspire a new suite of unit and integration tests appropriate for that authenticator.
The response from each test should be consistent with previous status implementations. For example:

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
  "status": "error",
  "error": "#<Errors::Authentication::AuthenticatorNotSupported: CONJ00001E Authenticator 'Authn<Type>' is not implemented in Conjur>"
}
```
***NOTE:*** All new errors should be placed in the `error.rb` and be referenced in the tests as displayed above.
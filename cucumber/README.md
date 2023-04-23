# Conjur Cucumber Tests

Cucumber tests are intended to test workflows from outside of Conjur. These
tests work through the Conjur API.

## Tag Descriptions

- Feature Area (`@api`, `@authenticators_azure`, etc.)

    These tags are added to each feature file and correspond to the feature
    sub-directory name.

- `@smoke`

    Indicates a "happy-path" test for a given feature in its simplest form.

- `@acceptance`

    Tests for a feature that verify its acceptance criteria. These include
    edge cases, unique data, etc..

- `@negative`

    A negative scenario is where invalid data/values/behavior are entered to
    generate an error condition.

    Example: entering a bad username and password should result in error/401
    unauthorized status

    Note: For negative AC - these should still be tagged as negative but also
    be included as part of acceptance tests

- `@performance`

    Indicates a time-based measurement test to verify feature performance.

## Best Practices

### Passing Data between Scenario Steps

As a scenario encapsulates a complex series of actions, information collected in one step may be required in a future step.  Let's look at the following example:

```
Scenario: A valid code with email as claim mapping
  Given I extend the policy with:
  """
  - !user alice@conjur.net
  - !grant
    role: !group conjur/authn-oidc/keycloak2/users
    member: !user alice@conjur.net
  """
  When I add the secret value "email" to the resource "cucumber:variable:conjur/authn-oidc/keycloak2/claim-mapping"
  And I fetch a code for username "alice@conjur.net" and password "alice" from "keycloak2"
  And I authenticate via OIDC V2 with code
  Then user "alice@conjur.net" has been authorized by Conjur
```

The code fetched in step:

```
And I fetch a code for username "alice@conjur.net" and password "alice" from "keycloak2"
```

is used in:

```
And I authenticate via OIDC V2 with code
```

Historically, we've used instance variables (`@variable_name`) to hold this information. Although this works, it makes understanding what information is required by a particular helper or step quite difficult. Often, it's easier to write new steps or helpers rather than attempt to understand existing ones (which leads to the sprawl of helpers and steps we currently see).

If you're sharing data between steps, please use the `Utilities::ScenarioContext`. It's available via `@scenario_context`.

```ruby
# Add data:
@scenario_context.add(:oidc_code, '<oidc-code>')
# or
@scenario_context.set(:oidc_code, '<oidc-code>')

# Retrieve previously saved data:
@scenario_context.get(:oidc_code) => '<oidc-code>'

# Exception thrown if key has not previously been set:
@scenario_context.get(:foo) => Exception "Scenario Context: 'foo' has not been defined"
```

After each scenario, the Scenario Context is recreated, to ensure data is not leaked between scenarios.

### Providing Configuration Data

Often Cucumber tests will need external data. This might be credentials to a remote service (ex. Okta), or defining default values (ex. Keycloak password). Historically this information has lived outside Cucumber, and is injected into scenarios via environment variables.

Although flexible, this lacks a way to define WHAT inputs are required and WHAT the default values are. As an alternative, the following step should be used to declare any external data:

```
Given the following environment variables are available:
  | context_variable    | environment_variable              | default_value             |
  | <variable-name>     | <optional-environment-variable>   | <optional-default-value>  |
```

In the above step, data is loaded into Scenario Context variable (as a symbol), either from the defined environment variable or defined default value. The environment variable takes precidence.

### Setting Conjur Variables

When testing components like authenticators, data needs to be saved in Conjur variables in order for the authenticator to work as expected. We prefer an explicit definition of variables and their corresponding values over the implicit:

```
I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/identity-from-decoded-token/RS256" in service "raw"
```

In the above, it's not at all clear to the reader what Conjur variable is being set. Instead, define variables in table form:

```
And I set the following conjur variables:
  | variable_id                                 | context_variable    | default_value |
  | conjur/authn-oidc/keycloak2/provider-uri    | oidc_provider_uri   |               |
  | conjur/authn-oidc/keycloak2/client-id       | oidc_client_id      |               |
```

Variable values can be defined either with previously defined Context Variables or a default value.

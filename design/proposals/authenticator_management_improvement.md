# Authenticators Management Improvement Proposal

- [Authenticators Management Improvement Proposal](#authenticators-management-improvement-proposal)
  - [Introduction](#introduction)
  - [Proposed Solution](#proposed-solution)
    - [Add Authenticator](#add-authenticator)
      - [Functionality](#functionality)
      - [Synopsis](#synopsis)
      - [Usage Example](#usage-example)
      - [API Specification](#api-specification)
    - [Delete Authenticator](#delete-authenticator)
      - [Functionality](#functionality-1)
      - [Synopsis](#synopsis-1)
      - [Usage Example](#usage-example-1)
      - [API Specification](#api-specification-1)
    - [Update Authenticator](#update-authenticator)
      - [Functionality](#functionality-2)
      - [Synopsis](#synopsis-2)
      - [Usage Example](#usage-example-2)
      - [API Specification](#api-specification-2)
    - [Enable Authenticator](#enable-authenticator)
      - [Functionality](#functionality-3)
      - [Synopsis](#synopsis-3)
      - [Usage Example](#usage-example-3)
      - [API Specification](#api-specification-3)
    - [Disable Authenticator](#disable-authenticator)
      - [Functionality](#functionality-4)
      - [Synopsis](#synopsis-4)
      - [Usage Example](#usage-example-4)
      - [API Specification](#api-specification-4)
  - [Implementation Details](#implementation-details)
  - [Backwards Compatibility](#backwards-compatibility)
  - [Performance](#performance)
  - [Security](#security)
  - [Documentation](#documentation)
  - [Version Update](#version-update)
  - [Delivery Plan](#delivery-plan)
  
## Introduction

Conjur authenticators are defined as sub-policies, under the `conjur` policy.  
Currently to define an authenticator, the user needs to complete the following steps:

- Read the documentation
- Understand how the authenticator policy is structured
- Create a policy yaml file that defines the authenticator
- Load the policy using Conjur CLI
- Fill the authenticator policy variables with their values
- Enable the authenticator through an environment variable or REST API call

To delete an authenticator, the user needs to complete these steps.  
Either:

- Create a policy with a `!delete` statement, on the authenticator policy
- Load the policy using Conjur CLI

Or:

- Update the `conjur` policy yaml file and take out the authenticator
- Reload the `conjur` policy using the `--replace` option  

The current user experience requires a certain level of expertise. The user needs to understand the policy structure of each authenticator and the process is comprised of multiple steps. This proposal offers an easier way for managing authenticators.

## Proposed Solution

The proposed solution is to add a few simple Conjur CLI commands (and possibly APIs, see two alternatives below), that would hide the complexity and provide a single step to perform each action:

### Add Authenticator

#### Functionality

Defines a new authenticator in Conjur. Behind the scenes, this command will creat the authenticator policy and fill it with all its required data. If the data is not required to be given by the user, like the `authn-k8s` CA cert and key, the information will be generated automatically.

#### Synopsis

conjur config authenticator add *authenticator-type/service-id* [*parameters*]

#### Usage Example

```shell script
$ conjur config authenticator add authn-oidc/my-idp --provider-uri my-uri --id-token-user-property prop
```

#### API Specification

- **URL**

    `/:authenticator/:service_id/:account`

    Example: `/authn-oidc/my-idp/my-company`

- **Method:**

    `POST`

- **URL Parameters:**

  - `:authenticator` - The authenticator type (e.g. authn-k8s, authn-oidc).
  - `:service_id` - The name of the specific authenticator instance to be created.
  - `:account` - The Conjur account in which to create the authenticator.

- **Return Value:**
  
  The API will return the appropriate HTTP code. If the operation was successful, it will also return the policy yaml that was loaded for the newly created authenticator.

### Delete Authenticator

#### Functionality

Deletes an existing authenticator in Conjur. Deletes the authenticator policy and deletes the authenticator from the enabled/disabled authenticators list.

#### Synopsis

conjur config authenticator delete *authenticator-type/service-id*

#### Usage Example

```shell script
$ conjur config authenticator delete authn-oidc/my-idp
```

#### API Specification

- **URL**

    `/:authenticator/:service_id/:account`

    Example: `/authn-oidc/my-idp/my-company`

- **Method:**

    `DELETE`

- **URL Parameters:**

  - `:authenticator` - The authenticator type (e.g. authn-k8s, authn-oidc).
  - `:service_id` - The name of the specific authenticator instance to be deleted.
  - `:account` - The Conjur account in which to delete the authenticator.

- **Return Value:**
  
  The API will return the appropriate HTTP code.

### Update Authenticator

#### Functionality

Updates an existing authenticator in Conjur. Updates the authenticator variables.

#### Synopsis

conjur config authenticator update *authenticator-type/service-id* [*parameters*]

#### Usage Example

```shell script
$ conjur config authenticator update authn-oidc/my-idp --provider-uri new-uri
```

#### API Specification

- **URL**

    `/:authenticator/:service_id/:account`

    Example: `/authn-oidc/my-idp/my-company`

- **Method:**

    `PATCH`

- **URL Parameters:**

  - `:authenticator` - The authenticator type (e.g. authn-k8s, authn-oidc).
  - `:service_id` - The name of the specific authenticator instance to update.
  - `:account` - The Conjur account in which to update the authenticator.

- **Return Value:**
  
  The API will return the appropriate HTTP code. If the operation was successful, it will also return the update policy yaml of the modified authenticator.

### Enable Authenticator

#### Functionality

Enables an authenticator in the Conjur database (can be overriden by environment variable).

#### Synopsis

conjur config authenticator enable *authenticator-type/service-id*

#### Usage Example

```shell script
$ conjur config authenticator enable authn-oidc/my-idp
```

#### API Specification

This already exists, please see the relevant documentation.

### Disable Authenticator

#### Functionality

Disables an authenticator in the Conjur database (can be overriden by environment variable).

#### Synopsis

conjur config authenticator disable *authenticator-type/service-id*

#### Usage Example

```shell script
$ conjur config authenticator disable authn-oidc/my-idp
```

#### API Specification

This already exists, please see the relevant documentation.

## Implementation Details

The new functionality will be developed on the Conjur side. New APIs will be exposed for this new functionality.  
The CLI will use these new APIs. In order for the CLI to remain up to date with the authenticator types, their required parameters and optional parameters, Conjur will expose an internal API that would provide this authenticator schema information. This API will be called by the CLI whenever this information will be needed. For example, when running `conjur config authenticator add/update {authenticator-type}/{service-id} --help`.

## Backwards Compatibility

- The authenticators keep their same structure in Conjur. Users could still manage them in the way it's done today.  
- These CLI commands are uniting policy loads and variable updates into a single step, therefore running the commands requires permissions to both load a policy under the `conjur` policy and to update the variables in that policy.

## Performance

The proposal only simplifies the steps, not adding or changing them, therefore the performance remain the same.

## Security

No security implications. These new CLI commands perform the same action, with an easier experience.

## Documentation

We will need to update the docs of every authenticator, to specify how to use the new CLI commands. In addition, we will need to add documentation for enabling/disabling authenticators.

## Version Update

This feature requires Conjur + CLI release.

## Delivery Plan

High level delivery plan includes the following steps:

| Functionality                           | Dev    | Tests  |
|-----------------------------------------|--------|--------|
| Adding authenticators in Conjur         | 5 days | 3 days |
| Adding authenticators in CLI            | 2 days | 1 days |
| Deleting authenticators in Conjur       | 3 days | 2 days |
| Deleting authenticators in CLI          | 1 days | 1 days |
| Updating authenticators in Conjur       | 2 days | 2 days |
| Updating authenticators in CLI          | 1 days | 1 days |
| Enabling authenticators in CLI          | 1 days | 2 days |
| Disabling authenticators in CLI         | 1 days | 2 days |
| Adding Conjur authn schema internal API | 2 days | 2 days |
| Modify deployment examples              | 3 days | -      |
| Documentation                           | 2 days | -      |
  
**Total: 39 days**

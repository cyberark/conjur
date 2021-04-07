# Variable Schema Validation Proposal

- [Variable Schema Validation Proposal](#variable-schema-validation-proposal)
  - [Introduction](#introduction)
  - [Current Limitations](#current-limitations)
  - [Proposed Solution](#proposed-solution)
    - [User Experience](#user-experience)
    - [Functionality](#functionality)
      - [JSON Schema Management](#json-schema-management)
        - [Creating and Updating JSON Schemas](#creating-and-updating-json-schemas)
        - [Deleting JSON Schemas](#deleting-json-schemas)
      - [Validating Variable Values Using a JSON Schema](#validating-variable-values-using-a-json-schema)
        - [Creating and Updating Variables](#creating-and-updating-variables)
        - [Deleting Variables](#deleting-variables)
      - [Secrets Encryption](#secrets-encryption)
      - [Built-in Schemas](#built-in-schemas)
      - [Automatic Permission Granting to Built-in Schemas](#automatic-permission-granting-to-built-in-schemas)
    - [Out of Scope - Future Development](#out-of-scope---future-development)
      - [Align Conjur Clients to a Single Variable Usage](#align-conjur-clients-to-a-single-variable-usage)
      - [Align Conjur Rotators to a Single Variable Usage](#align-conjur-rotators-to-a-single-variable-usage)
      - [Granular Updates of Variable Values](#granular-updates-of-variable-values)
  - [Main Advantages and Expected Value From This Proposal](#main-advantages-and-expected-value-from-this-proposal)
  - [Affected Areas](#affected-areas)
  - [Backwards Compatibility](#backwards-compatibility)
  - [Performance](#performance)
  - [Security](#security)
  - [Documentation](#documentation)
  - [Version Update](#version-update)
  - [Delivery Plan](#delivery-plan)
    - [Minimal Functionality](#minimal-functionality)
    - [Extended Functionality](#extended-functionality)
  
## Introduction

Conjur variables are resources that allow a user or an application to define and store sensitive information.

In many cases, such sensitive information is comprised of multiple pieces that are tightly coupled and together represent a complete object. A few examples:

- In order to access a MySQL database, a user needs a username, a password and an address, URL or connection string.
- In order to access a REST API exposed by a certain service, a user might need either a username and password, a private key and a public certificate, or a token. In addition, the user will need the server public certificate and its address.

Currently, this is handled by defining multiple variables in Conjur. Each variable contains a single value, such as a username, a password, etc. To bundle these pieces together, we use a naming convention. For example:

```yaml
- !policy
  id: my-policy
  body:
  - &vars
    - !variable mysql-db-creds/password
    - !variable mysql-db-creds/username
    - !variable mysql-db-creds/address
    - !variable mysql-db-creds/port

  - !host my-app
  
  - !permit
    role: !host my-app
    privileges: [ read,execute ]
    resource: *vars
```

## Current Limitations

- Multiple variables cannot be updated together, as a single transaction. This might lead to a momentary inconsitency when for example, a username is updated, the password should probabaly be updated as well.
- There is no enforcement on the content of a variable, which can lead to unintended invalid content.
- There is no enforcement on the group of variables needed for a certain use case. For example, a database connection requires a username, password, connection URL or address and port. A user could accidentally forget to specify a certain needed variable.

## Proposed Solution

The proposed solution is to add the ability to use JSON schemas and link them to variables, for which we want validation of their content. This will allow a single variable to store multiple, related values. While it's already possible today, to store JSON structured information in a variable, this proposed feature adds two added values:

- The JSON structure is validated and enforced. If the input is invalid, the user will get a proper error message and the variable update will be denied.
- The JSON structure will not be encrypted completely, but only the sensitive information. This will allow future seach capabilities based on the non sensitive information.

### User Experience

Let's have a look at the following example:

```yaml
- !policy
  id: my-policy
  body:
  - !variable
    id: mysql-db-creds
    annotations:
      schema-reference: !variable /conjur/schemas/mysql-schema

  - !host my-app
  
  - !permit
    role: !host my-app
    privileges: [ read,execute ]
    resource: !variable mysql-db-creds
```

And

```yaml
- !policy
  id: conjur/schemas
  body:
  - &schemas
    - !variable
      id: mysql-schema
      annotations:
        schema: true

  - !permit
    role: !group /conjur/all
    privileges: [ read,execute ]
    resource: *schemas
```

In the example above, the `/conjur/schemas/mysql-schema` variable will be updated with the following value:

```json
{
  "$id": "https://cyberark.com/mysql.schema.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "MySQL Creds",
  "type": "object",
  "properties": {
    "username": {
      "type": "string",
      "description": "The MySQL username"
    },
    "password": {
      "type": "string",
      "description": "The MySQL password",
      "minLength": 12,
      "maxLength": 40,
      "pattern": "[A-Za-z0-9]"
    },
    "address": {
      "type": "string",
      "description": "The MySQL address"
    },
    "port": {
      "description": "The MySQL port number",
      "type": "integer",
      "minimum": 1,
      "maximum": 65535
    }
  },
  "required": ["username", "password"],
  "additionalProperties": false,
  "non-secrets": [
      "username", "port", "address"
    ]
}
```

And the `mysql-db-creds` variable could be updated with the following value:

```json
{
  "username": "my-user",
  "password": "my-password-12345",
  "address": "my-db.com",
  "port": 3306
}
```

### Functionality

#### JSON Schema Management

JSON schemas are variables that have the following annotation:

```yaml
schema: true
```

##### Creating and Updating JSON Schemas

When creating or updating a JSON schema, the user will create a variable and annotated it as a JSON schema (schema: true). Then Conjur will validate the variable content, to ensure it's a valid JSON schema. A proper error message will be given if the input is not a valid JSON schema.

##### Deleting JSON Schemas

When deleting a JSON schema variable, if there are existing variables with references to that deleted JSON schema, the references will be automatically removed. Therefore these existing variables will be left as general variables with no schema validation.

#### Validating Variable Values Using a JSON Schema

Variables that their content is validated by a JSON schema have the following annotation:

```yaml
schema-reference: !variable full-path-of-schema-variable
```

##### Creating and Updating Variables

If a variable was annotated with a schema reference (schema-reference: schema-variable-name), then Conjur will validate the variable content, using the JSON schema that is specified in the `schema` attribure of that variable.

For the example above, Conjur will use the JSON schema specified in `conjur/schemas/mysql-schema` to verify the content of `mysql-db-creds`. This verification includes:

- `username` and `password` are mandatory properties.
- `address` and `port` are allowed properties.
- `port` must contain a valid port number.
- `password` must align to a sufficient complexity.

If the variable content is invalid, the user will get an HTTP code of 422 (Unprocessable Entity) and the body of the response will also contain an elaborative error message that explains what part of the input was found to be invalid.

For the example above, if the user would provide a string as the port value, the following error message will be returned:

```text
Message: Invalid type. Expected Integer but got String.
Schema path: https://cyberark.com/mysql.schema.json#/properties/port/type
```

At first stage, a user that wants to update a specific field within the JSON structure, will read the variable, change its value appropriately and call Conjur to update the variable. In a later stage, we will add support for updating specific fields directly through the variable API.

##### Deleting Variables

No changes in deletion of variables that are referenced to JSON schemas. The behavior remains the same as regular variables.

#### Secrets Encryption

The JSON schema can contain a property called `non-secrets` which expects an array of JSON schema property names. The properties specified in this array will not be encrypted in the database, along with the JSON structure. The unspecified attributes, will by default get encrypted. This allows the protection of sensitive data while also allowing the non-sensitive values to be searchable. Meaning that the variable will not be encrypted as a whole, but only the sensitive attributes in the JSON structure.

For the example above, the `mysql-db-creds` variable will be saved in the database as follows:

```json
{
  "username": "my-user",
  "password": "U2FsdGVkX19Ji6JpgnVHW3V47OtMJwuKi1Yf9nc0aP5QcuzdnIrpzZ2zMC90f24g",
  "address": "my-db.com",
  "port": 3306
}
```

Before the variable value is returned to the client, the secret attributes are decrypted so that the given example above, would look like this:

```json
{
  "username": "my-user",
  "password": "my-password",
  "address": "my-db.com",
  "port": 3306
}
```

#### Built-in Schemas

To simplify the user experience, Conjur can come with prdefined JSON schemas for the most common secrets use cases. The list of predefined schmeas should include:

- Database secrets - Oracle, MSSQL, MySQL, Postgres, MariaDB, DB2.
- Cloud access keys - AWS, Azure, GCP.
- X509 certificates.
- JWTs

Write about the advantages of atomicity, minimal changes in the database to implement this and so on.

#### Automatic Permission Granting to Built-in Schemas

In order to provide access for any role to the built-in schemas, a new built-in group should be introduced: `conjur/all`. All roles in the Conjur account should be added to this group automatically, thus keeping this group always up to date with all the roles that exist in the account.

Usage example:

```yaml
- !permit
  role: !group /conjur/all
  privileges: [ read,execute ]
  resource: !variable my-var
```

### Out of Scope - Future Development

#### Align Conjur Clients to a Single Variable Usage

Modify our examples and integrations, such as the Conjur Summon provider, to leverage this new single variable JSON structure, instead of multiple variables.

#### Align Conjur Rotators to a Single Variable Usage

Modify the existing Conjur rotators, to update a JSON structured variable.

#### Granular Updates of Variable Values

As a first step, updating a variable value means that the entire JSON structure should be written at once. In the future, for a granular update that would allow the user to update a specific field within the JSON structure. For example, if a variable contains a JSON with two fields: `username` and `password`, the variable API will be able to update one of the fields, without replacing the whole JSON.

## Main Advantages and Expected Value From This Proposal

- We leverage a standard way to enforce the content of the variable, with a well known JSON schema.
- Tightly coupled values, such as username and password, are updated together in a single transaction. This will prevent momentary inconsistency in which each value was updated independently, one after the other.
- The user will not have to look in the documentation or to understand the required variables, their structure or allowed input. Conjur will provide this feedback when an update attempt is made.
- The feature does not require changes in the database schma, only in new built-in content.
- The returned variable is in a JSON structure, same as the rest of our APIs responses.

## Affected Areas

- The new functionality will be developed in the Conjur server and the policy parser.
- No new APIs are needed, since all the functionality will be given as part of the policy loading.
- No changes required in the database structure. But new built-in data should be added into the database tables, when they are initially created (clean install) or when an upgrade occurs from any prioir version.

## Backwards Compatibility

Variables that do not have a reference to a schema, will not enforce the content. Therefore, behavior of all existing variables and newly created variables without the schema attribute, will work the same as it has been working.

## Performance

Performance tests are required in order to make sure the schema validation doesn't introduce a major performance effect. The risk of a significant performance change is low.

## Security

Introducing a new `conjur/all` group can potentially be dangerous for uncautios users. Any permission given to that group will be given to all roles in the Conjur account, so proper warnings should be given to the user, at least in our documentation.

## Documentation

We will need to update the docs of this new functionality, under the policy management section. The documentation should include the following:

- How the variable schema validation works
- How can a user use the built-in schemas
- How can a user create new schemas
- Policy examples with schema examples. Explain how the variable content is enforced in these examples.

## Version Update

This feature requires a Conjur release.

## Delivery Plan

### Minimal Functionality

Includes variable content neforcement with JSON schema

| Functionality                                                                                   | Dev    | Tests  |
|-------------------------------------------------------------------------------------------------|--------|--------|
| Adding input validation to variables that will contain JSON schemas                             | 3 days | 3 days |
| Adding input validation to variables that are referenced to JSON schemas                        | 5 days | 3 days |
| Adding cascading annotation removal to variables that had references to deleted schemas         | 2 days | 3 days |
| Documentation                                                                                   | 3 days | -      |
  
**Total: 22 days**

### Extended Functionality

Includes built-in JSON schemas, selective encryption of the secrets attributes in the JSON structure, and automatic permission grant for all the users on the built-ing schemas.

| Functionality                                                                                   | Dev    | Tests  |
|-------------------------------------------------------------------------------------------------|--------|--------|
| Adding built-in schemas to the database migration process                                       | 5 days | 2 days |
| Adding built-in `all` group                                                                     | 2 days | 2 days |
| Every new role is automatically added to the `all` group                                        | 4 days | 2 days |
| Change variable encryption to the secret attributes only, instead of the whole variable payload | 3 days | 2 days |
| Documentation                                                                                   | 3 days | -      |

**Total: 25 days**
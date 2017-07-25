# Group Secrets

## Create Secret [/secrets/:account/:kind/:identifier]

### Create Secret [POST]

Creates a secret value in the specified variable.

**Request Body**

|Description|Required|Type|Example|
|-----------|--------|----|-------|
|Secret Value|yes|`Binary`|"3ab2fabadea7e7b68acc893e"|

**Respones**

|Code|Description|
|----|-----------|
|201|The secret values was created successfully|
|401|The user is not logged in|
|403|The user did not have 'update' privilege on the variable|
|404|The secret does not exist or does not have a stored value|

+ Response 201 (application/json)

## Show Secret [/secrets/:account/:kind/:identifier{?version}]

### Show Secret [GET]

Fetch the value of a secret in the specified variable.

**Respones**

|Code|Description|
|----|-----------|
|200|The secret values was retrieved successfully|
|401|The user is not logged in|
|403|The user did not have 'execute' privilege on the secret|
|404|The secret does not exist or does not have a stored value|
|422|The version 

+ Parameters
    + version: 1 (integer)

+ Response 200 (application/json)

## Batch Secret Retrieval [/secrets{?variable_id}]

### Batch Secret Retrieval [GET]

Fetch the values of a list of variables. This operation is more efficient than
fetching the values one by one.

**Response**

|Code|Description|
|----|-----------|
|200|All secret values were retrieved successfully|
|401|The user is not logged in|
|403|The user did not have 'execute' privilege on one or more secrets|
|404|One or more secrets do not exist or do not have a stored value|
|422|variable_id parameter is missing or invalid|

+ Parameters
    + variable_id: cucumber:variable:secret1,cucumber:variable:secret2 (array) - Resource IDs of the variables containing the secrets you wish to retrieve.

+ Response 200 (application/json)

        {
            "cucumber:variable:secret1": "secret_data",
            "cucumber:variable:secret2": "more_secret_data"
        }

# Credential Factory

Generates credentials dynamically from a backend which supports it, such as AWS Security Token Service.

# Policy configuration

Load a policy file, such as [aws_credential_factory.yml](./run/aws_credential_factory.yml). In one policy, such as `aws-dev`, define variables for AWS access key id, secret, and region. For example:

```
- &variables
  - !variable access_key_id
  - !variable secret_access_key
  - !variable region
```

Create a `secrets-users` group with access to these credentials.

Load valid credentials into the variables and set the `region`.

In another policy, such as `myapp`, define a `!credential-factory` object and add an entitlement which grants it the `secrets-users` group (for example, `aws-dev/secrets-users`. The Credential Factory will access these credentials in order to call the AWS Security Token Service [GetFederationToken](https://docs.aws.amazon.com/STS/latest/APIReference/API_GetFederationToken.html) function. You must provide an annotation `credential-factory/policy`, which is the IAM policy which will be applied to the generated credentials.

You can also define optional annotations `credential-factory/duration-seconds` and `credential-factory/user-name`. 

Then, for any role which you want to use the Credential Factory, give it the `execute` privilege on the `!credential-factory`. The client role **does not** need any privileges on the long-lived AWS credentials.

The client role can now fetch a secret using the Conjur API using the object id `<acct>:credential_factory:<the-factory-id>`, just like fetching a secret from a variable using `<acct>:variable:<the-variable-id>`. 

The data will be returned in JSON format with the following fields:

* access_key_id
* secret_access_key
* session_token
* expiration
* federated_user_id
* federated_user_arn

The MIME type is `application/json`.

# Example

1. Start up `./dev/start.sh`
2. In the `conjur` container, run the server using the AWS credential factory example policy:

```
$ conjurctl server -a cucumber -f ./run/aws_credential_factory.yml
...
Loaded policy in 0.577820945 seconds
```

3. Open `rails console` of the `conjur` container in a separate terminal.
4. Populate the secrets:

```
> r = Resource["cucumber:variable:aws/dev-account/access_key_id"]
> Secret.create resource: r, value: "<your-access-key-id>"
> r = Resource["cucumber:variable:aws/dev-account/secret_access_key"]
> Secret.create resource: r, value: "<your-secret>"
> r = Resource["cucumber:variable:aws/dev-account/region"]
> Secret.create resource: r, value: "us-east-1"
```

5. Now you can use CredentialFactory to generate credentials:

```
> puts JSON.pretty_generate CredentialFactory.values Resource["cucumber:credential_factory:myapp"]
{
  "access_key_id": "ASIAI6...F7KPBKA",
  "secret_access_key": "EhyQYceI...arRtkZfYugB9dDM6",
  "session_token": "FQoDYXdzEH4aD...7bz7Nw+NL0mKNr8ztYF",
  "expiration": "2018-04-15 22:04:26 UTC",
  "federated_user_id": "<acct-id>:myapp",
  "federated_user_arn": "arn:aws:sts::<acct-id>:federated-user/myapp"
}
```

# TODO

* Should the `expiration` result be set as a header instead?


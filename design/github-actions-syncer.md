# Conjur Synchronization

## Challenge
Github Actions can leverage Github Secrets to keep credentials secure.

An organization that wants to leverage Github Actions as part of their workflow faces a serious integration challenge if they want to avoid creating security islands (credentials duplicated in multiple locations).

  Actions currently lack a concept of identity. As a result, an , an organization needs to create a DAP/Conjur host (and API key). This API key needs to be stored as a GH Secret, and an SDK be written to retrieve credentials from Conjur/DAP. This marks a serious barrier to entry.

## Potential Solution

Enable Conjur to be able to sync credentials with Github Secrets. This would provide a low friction mechanism to enable a single source of truth while allowing the the a developer to leverage the integrations the GH Actions platform provides.

## Sample Outcomes

### Publish a release to Dockerhub

Allow an action to leverage credentials managed by Conjur/DAP + EPV to publish an image artifact to Docker Hub.

#### What Happens

Given the following policy.

```yml
- !policy
  id: dockerhub
  annotations:
    github_secrets/sync: enabled
    github_secrets/api_key: !variable /external-services/github/api-key
    github_secrets/repositories: ['cyberark/secretless-broker']

  body:  
    - !variable
      id: login
      annotations:
        github_secrets/value: DOCKERHUB_LOGIN

    - !variable
      id: password
      annotations:
        github_secrets/value: DOCKERHUB_PASSWORD
```

1. A users loads the above policy into Conjur/DAP.
1. A user set's the variable values for `dockerhub/login` and `dockerhub/password`.
1. When a variable value changes, then:
    1. Connection is created with Github using the key stored in the `/external-services/github/api-key` variable.
    1. For each repository in the `github_secrets/repositories` list (`cyberark/secretless-broker`) set the value stored in the Conjur variable to the Secret defined in `github_secrets/value`.

        > ex. If login variable value is `cyberark`, then a Github Secret would be created, `DOCKERHUB_LOGIN` with a value of `cyberark`.
  1. Success or failure of update is noted in an audit event.

### Provide an API key to a Github Action

Provide an Code Climate API to a Github Action

#### What Happens

Given the following policy.

```yml
- !variable
  id: codeclimate-api-key
  annotations:
    github_secrets/sync: enabled
    github_secrets/value: CODECLIMATE_KEY
    github_secrets/api_key: !variable /external-services/github/api-key
    github_secrets/repositories: ['cyberark/secretless-broker']
```

1. A users loads the above policy into Conjur/DAP.
2. A user set's the variable values for `codeclimate-api-key`.
3. When the `codeclimate-api-key` variable value changes:
    1. Connection is created with Github using the key stored in the `/external-services/github/api-key` variable.
    2. For each repository in the `github_secrets/repositories` list (`cyberark/secretless-broker`) set the value stored in the Conjur variable to the Secret defined in `github_secrets/value`.

        > ex. A Github Secret would be created, `CODECLIMATE_KEY` with a value defined in the Variable `codeclimate-api-key`.
1. Success or failure of update is noted in an audit event.

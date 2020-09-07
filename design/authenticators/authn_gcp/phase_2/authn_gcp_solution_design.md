# Solution Design - GCP Authenticator

## Table of Contents
- [Glossary](#glossary)
- [Useful links](#useful-links)
- [Issue description](#issue-description)
- [Out of scope](#out-of-scope)
- [Solution](#solution)
  * [GCP Resource Restrictions](#gcp-resource-restrictions)
  * [Environment-provided service account google identity](#environment-provided-service-account-google-identity)
  * [Access GCP authenticator](#access-gcp-authenticator)
  * [Backwards compatibility](#backwards-compatibility)
  * [Performance](#performance)
  * [Affected Components](#affected-components)
- [Cross-team dependencies](#cross-team-dependencies)
- [Security](#security)
- [Test Plan](#test-plan)
- [Logs](#logs)
  * [Audit](#audit)
- [Documentation](#documentation)
- [Automation Design](#automation-design)
- [Open questions](#open-questions)
- [Delivery plan](#delivery-plan)
  * [Total EE25](#total-ee25)
  * [Parallelism](#parallelism)
    + [Ramp up EE0](#ramp-up-ee0)
  * [Infrastructure and preparations EE3](#infrastructure-and-preparations-ee3)
    + [Designs EE0](#designs-ee0)
    + [Spikes and researches EE1](#spikes-and-researches-ee1)
    + [Implementation EE2](#implementation-ee2)
    + [Testing EE7](#testing-ee7)
    + [Security EE1](#security-ee1)
    + [Docs EE4](#docs-ee4)
  * [Demo EE1](#demo-ee1)
  * [Left overs and refactoring EE6](#left-overs-and-refactoring-ee6)

## Glossary
Please read also [solution design 1st phase Glossary section](../phase_1/authn_gcp_solution_design.md) 

| **Term** | **Description** |
|----------|-----------------|
|  Cloud function | Scalable Functions-as-a-Service (FaaS) to run your code with zero server management.                |


## Useful links
- [Feature doc](https://app.zenhub.com/workspaces/palmtree-5d99d900491c060001c85cba/issues/cyberark/conjur/1804)
- [Cloud function identity](https://cloud.google.com/functions/docs/securing/function-identity)

## Issue description
We want enable google cloud functions to authenticate Conjur with their google identity in order to retrieve secrets.

## Out of scope
* We will not support cloud function with [end user identities](https://cloud.google.com/functions/docs/securing/authenticating#end-users) 
which are more similar to our OIDC authenticator and not GCP.

* Follower on GKE benchmark tests will be handled in another epic

* Policy validation effort will be handled in another epic

* As 1st phase we will support only conjur hosts, and we will not failed users which theoretically should works

## Solution
In continue to GCP authenticator 1st phase which we supported GCE hosts to authenticate against Conjur, 
in this 2nd phase we will add support of google cloud functions to be able to authenticate Conjur  by delivering their google identity as JWT token

Since most of the designs parts are similar to [solution design 1st phase](../phase_1/authn_gcp_solution_design.md),
i will only elaborate on the changes and the new parts.

### GCP Resource Restrictions
In different to GCE token which in order to authenticate with Conjur, GCP-specific fields will need to be provided in the host annotations of the Conjur host 
identity with the following options:

In the 1st phase, for applications running in GCE we have supported the following resource restrictions as Conjur host annotations:

* **project-id** - A customizable unique identifier of the Google Cloud Platform project.
* **instance-name** - The name of the GCP machine.
* **service-account-id** - The GCE instance identity (Service Account).   
* **service-account-email** - The email of the instance identity (Service Account).

In this 2nd phase, for cloud functions the JWT identity token is a bit different and similar to the GCE standard token (not full token),
```json
  "azp": "111419367255973271886",
  "email": "nessi-service-account-test@refreshing-mark-284016.iam.gserviceaccount.com",
  "email_verified": true,
  "exp": 1599392637,
  "iat": 1599389037,
  "iss": "https://accounts.google.com",
  "sub": "111419367255973271886"
```
and therefore wi will support only the following resource extractions:

* **service-account-id** - The cloud function instance identity (Service Account).   
* **service-account-email** - The email of the instance identity (Service Account).

THe logic will remain the same as the 1st phase:
At least one of the above should be provided, if more than 1 is provided, we will authenticate them with `AND` logic.


The YAML snippet below depicts Conjur host policy that can be identified using GCP identifiers:
```yaml
- !policy
  id: <policy-id>
  body:
    - !group
 
    - &hosts
      - !host
        id: myapp
        annotations:
          authn-gcp/service-account-id: <service-account-id>
          authn-gcp/service-account-email: <service-account-email>
           
    - !grant
      role: !group
      members: *hosts
          
- !grant
  role: !group /conjur/authn-gcp/apps
  member: !group <policy-id>
```

In order to support both GCE and Cloud function we will delete the token structure validation in the code, 
we enforced the token to contains full GCE token type.

### Environment-provided service account google identity
In similar to 1st phase, the api to fetch the cloud function identity is the same.
Reminder: the requirement for the audience format is valid also for this phase. `conjur/<account-name>/<host-id>`

the only change is that for cloud function there is no `format` parameter like GCE.
 
**Example:** 
Run the following from the Cloud Function code:
```python
    import requests
    # TODO<developer>: set these values
    REGION = 'us-central1'
    PROJECT_ID = 'refreshing-mark-284016'
    RECEIVING_FUNCTION = 'nessi-test-function'
    AUDIENCE = 'conjur_host_id'
    # Constants for setting up metadata server request
    # See https://cloud.google.com/compute/docs/instances/verifying-instance-identity#request_signature
    function_url = f'https://{REGION}-{PROJECT_ID}.cloudfunctions.net/{RECEIVING_FUNCTION}'
    token_full_url = \
    f'http://metadata/computeMetadata/v1/instance/service-accounts/default/identity?audience={AUDIENCE}'
    token_headers = {'Metadata-Flavor': 'Google'}
    
    def fetch_token(request):
    # Fetch the token
    token_response = requests.get(token_full_url, headers=token_headers)
    jwt = token_response.text
    return jwt
```

### Access GCP authenticator
Same as 1st phase

### Backwards compatibility
None because this is a new feature.

### Performance
Same as 1st phase:
GCP authenticator performance should conform with our other authenticators with an average call time of 1 second.

### Affected Components
- Conjur

- DAP

## Cross-team dependencies
* Infra team - the capability to fetch cloud function JWT token as part of our CI pipeline 

## Security
None, we are relying the same mechanism as 1st phase

## Test Plan
[Link to confluence](https://ca-il-confluence.il.cyber-ark.com/display/rndp/Conjur+GCP+authenticator+2nd+phase+-+Test+plan#/) 

## Logs
Will be changed as part of the implementation stage

### Audit 
Same logic like all other authenticators.

## Documentation
* Document examples of how to fetch google identity in google cloud functions
* Document the solution supported use cases, logs and supportability section 


## Automation Design
Please read [solution design 1st phase Automation section](../phase_1/authn_gcp_solution_design.md) 

In a similar approach we took in 1st phase, we will add the capability to create cloud functions tokens,
in the jenkins machine as part of the CI process and will inject them to the cucumber flow to be used in the integrations tests.


## Open questions

## Delivery plan
**Merging to master strategy**

In this feature we are prefer to work with a feature branch instead of small PRs to master,
Since we are planning to deliver it before the planned release version.

### Total EE27

### Parallelism
The feature can be paralleled to 2 team members all the way

#### Ramp up EE0
already covered in research phase

### Infrastructure and preparations EE4
1. Create side branch **E0**

    1.1 Create side branch from 11.7 release branch
    
    1.2 Cherry pick commit of changing GCP name ([commit id](https://github.com/cyberark/conjur/commit/601db2781a08b5fb1b15bb262d846239b486092a))
2. Support Google cloud functions in dev/start script **EE2**
3. Update jenkins file in DAP and OSS to support Google cloud functions tokens **E1**
4. Release from side branch **E1**

    4.1 Update Conjur and DAP versions 
    
    4.2 Release DAP as CA from side branch 
    
#### Designs EE0
None.
Note: LLD designs need will be decided at implementation level 

#### Spikes and researches EE1
1. Does google app engine will be also supported? **E1**

#### Implementation EE3
1. Add support for Google cloud functions **E1**
2. Enhance logs and supportability **EE1**
3. Merge back to the master after release **EE1**

#### Testing EE7
1. OSS - Implement integration tests **EE3**
2. DAP - Implement integration tests for **EE2**
3. Setting customer env **EE1**
4. Manual tests according to docs (customer env) **EE1**

#### Security EE1
1. Review EE1

#### Docs EE4 
1. Document examples of how to fetch google cloud function identity in GCP **EE2**
2. Document the solution supported use cases, logs and supportability section **EE2**

### Demo EE1
1. Record a demo for GCE and Cloud function use cases **E1**

### Left overs and refactoring EE6
1. LLD for K8S, Azure ang GCP to use same component of ValidateResourceRestrictions class **EE3**
2. Implement LLD1 **EE3**

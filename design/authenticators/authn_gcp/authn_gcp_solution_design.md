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
  * [Design](#design)
    + [Class diagram](#class-diagram)
    + [GCP authenticator flow](#gcp-authenticator-flow)
  * [Backwards compatibility](#backwards-compatibility)
  * [Performance](#performance)
  * [Affected Components](#affected-components)
- [Security](#security)
- [Test Plan](#test-plan)
- [Logs](#logs)
  * [Error Log level](#error-log-level)
  * [Debug Log level](#debug-log-level)
  * [Audit](#audit)
- [Documentation](#documentation)
- [Automation Design](#automation-design)
  * [Run Integration Tests in OSS](#run-integration-tests-in-oss)
    + [GCP Variables in Tests](#gcp-variables-in-tests)
  * [GCP for Tests](#gcp-for-tests)
  * [Run authn-gcp Requests](#run-authn-gcp-requests)
    + [Issue GCP Identity token](#issue-gcp-identity-token)
  * [Requirements from DevOps](#requirements-from-devops)
  * [Version update](#version-update)
- [Open questions](#open-questions)
- [Implementation plan](#implementation-plan)
  * [Total EE39](#total-ee39)
    + [Ramp up EE0](#ramp-up-ee0)
    + [Designs EE0](#designs-ee0)
    + [POC and researches EE3](#poc-and-researches-ee3)
    + [Implementation EE14](#implementation-ee14)
    + [Testing EE16](#testing-ee16)
    + [Security EE2](#security-ee2)
    + [Docs EE4](#docs-ee4)
  * [After GA EE6 + ??](#after-ga-ee6-----)
    + [Designs](#designs)
    + [Implementation](#implementation)
    + [Testing](#testing)
  * [Implement JWT authenticator as Beta EE18](#implement-jwt-authenticator-as-beta-ee18)
    + [Designs](#designs-1)
    + [Implementation](#implementation-1)
    + [Security EE2](#security-ee2-1)
    + [Testing](#testing-1)

## Glossary

| **Term** | **Description** |
|----------|-----------------|
|  GCP| Google Cloud Platform                 |
|  Google compute engine (GCP)| Virtual machine in google (similar to AWS EC2)                  |
|  Environment-provided service account| An identity for accessing private data on behalf of a service account inside Google Cloud environments |
|  Service account key| App can self sign a google token with the service account key in order to accessing private data on behalf of a service account outside Google Cloud environments|



## Useful links
- [Feature doc](https://app.zenhub.com/workspaces/palmtree-5d99d900491c060001c85cba/issues/cyberark/conjur/1711)
- [GCP authentication overview]( https://cloud.google.com/docs/authentication)
- [Google metadata server](https://cloud.google.com/compute/docs/storing-retrieving-metadata#querying)
- [Type of service accounts](https://cloud.google.com/iam/docs/service-accounts#types)
- [Creating short-lived service account credentials](https://cloud.google.com/iam/docs/creating-short-lived-service-account-credentials)

## Issue description
Enable GCP hosts to authenticate to Conjur using their Google identity as credentials in order to issue a Conjur token
that will allow them to access secrets in Conjur.

## Out of scope
* The only authentication strategy we are supporting is Google [Service Account](https://cloud.google.com/iam/docs/service-accounts) 
in Google [Compute Engine](https://cloud.google.com/compute).
Other strategies are not supported: Service account keys, OAuth 2.0 client, API keys.
Other google components are not supported: App Engine, GKE, Cloud Run and Cloud Functions.

* Google-managed service accounts are out of scoped, 
you can find more info about different service accounts, [here](https://cloud.google.com/iam/docs/service-accounts#types)

## Solution
A new GCP authenticator will be added to Conjur, GCP hosts will authenticate with this authenticator by presenting their 
host Conjur identity and Google identity in a signed JWT token.

We will support only the following service accounts types:
* Default service accounts - automatically granted by google
* User-managed service accounts - created by the user


As mentioned in the [feature doc](https://ca-il-confluence.il.cyber-ark.com/display/rndp/Conjur+GCP+Authenticator#/), 
before any authentication request is sent to Conjur, the admin will load the authenticator policy:
 
The YAML snippet below depicts the Google authenticator policy in Conjur:

**Note:** The `service-id` is not allowed in this authenticator since its redundant, we will have only one `authn-gcp` in Conjur.
```yaml
# policy id needs to match the convention `conjur/authn-gcp`
- !policy
  id: conjur/authn-gcp
  body:
  - !webservice
      
  - !group apps
  
  - !permit
    role: !group apps
    privilege: [ read, authenticate ]
    resource: !webservice
```

All of the following configurations will be hardcoded in Conjur:
**Note:** Those configuration are not exposed to the customer, in order to have a better UX, 
the ideal way is to expose them and to have a default values, 
but currently we do not have the infrastructure where and how to define system internal configuration or default values.

* **provider-uri**: `https://www.googleapis.com/oauth2/v1/certs` #represnts the address to fetch the public key in order
 to validate the JWT token.
* **mandatory-claims**: `iss, exp, iat` #the list of the mandatory claims to validate in the JWT token.
* **iss**: `https://accounts.google.com` #the issuer claim we should validate in the JWT token

### GCP Resource Restrictions
To authenticate with Conjur, GCP-specific fields will need to be provided in the host annotations of the Conjur host 
identity with the following options:

* **project-id** - A customizable unique identifier of the Google Cloud Platform project.
* **instance-name** - The name of the GCP machine.
* **service-account-id** - The GCE instance identity (Service Account).   
* **service-account-email** - The email of the instance identity (Service Account).

At least one of the above should be provided, if more than 1 is provided, we will authenticate them with `AND` logic.

A Conjur host will be defined as follows with their annotations holding GCP-specific identification attributes.

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
          authn-gcp/instance-name: <instance-name>
          authn-gcp/project-id: <project-id>
          authn-gcp/service-account-id: <service-account-id>
          authn-gcp/service-account-email: <service-account-email>
           
    - !grant
      role: !group
      members: *hosts
          
- !grant
  role: !group /conjur/authn-gcp/apps
  member: !group <policy-id>
```

### Environment-provided service account google identity
In order to authenticate with Conjur GCP authenticator, a GCE instance first needs to fetch its environment-provided 
identity.

**Example:** 
Run the following from the GCP machine:

`curl \ --header Metadata-Flavor: Google" \ --get \ --data-urlencode "audience=conjur/<account-name>/<host-id>" \ --data-urlencode "format=full" 
\ "http://metadata/computeMetadata/v1/instance/service-accounts/default/identity`

**Note**: the `format=full` query string parameter is mandatory otherwise the output token will not include the compute 
engine metadata claim and Conjur will not be able to identify the caller.

The audience value must to be in following format:  `conjur/<account-name>/<host-id>` 

For example: `conjur/myorg/myapp`

The JSON snippet below depicts a GCP identity JWT token issued by Google meta data service:

```json
{
  "aud": "conjur/myorg/myapp",
  "azp": "110987294251917851298",
  "email": "716149158341-compute@developer.gserviceaccount.com",
  "email_verified": true,
  "exp": 1595160638,
  "google": {
    "compute_engine": {
      "instance_creation_timestamp": 1595155766,
      "instance_id": "4340508760561261530",
      "instance_name": "vm-for-gcp",
      "project_id": "eng-serenity-231813",
      "project_number": 716149158341,
      "zone": "us-central1-a"
    }
  },
  "iat": 1595157038,
  "iss": "https://accounts.google.com",
  "sub": "110987294251917851298"
}
```

The following is a mapping of Host annotations with the values we will be extracting in the google JWT token:

| Host annotation                                                      | GCP JWT token             | 
|----------------------------------------------------------------------|--------------------------------|
| `authn-gcp/project_id`                                               | `google/compute_engine/project_id`     |
| `authn-gcp/instance_name`                                            | `google/compute_engine/instance_name`  |
| `authn-gcp/service_account_id`                                       | `sub` claim                            |
| `authn-gcp/service_account_email`                                    | `email` field                          |

### Access GCP authenticator
Send the following POST request:

`https://<DAP-server-hostname>/authn-gcp/<account>/authenticate`

The URL will not include the following:
* The host id as it is written in the token’s audience claim
* There is no service-id in this authenticator 


|  | |
|----------|-----------------|
| **Header**          |  Content-Type: application/x-www-form-urlencoded               |
| **Body**         |  The body must include the GCP jwt token for GCE instance. jwt=eyJhbGciOiJSUzI1NiIs......uTonCA               |

### Design
When we got the requirement to implement GCP authenticator the first thought was: if we had a generic JWT authenticator 
we could support it, maybe not with the best UX but surly we could present a proof of concept.

So the goal of this deign is to present a GCP implementation plan with a small effort to support JWT authenticator as 
well.
While the main differences between them is UX and configuration options:
GCP authenticator - should focus on UX in Google Cloud Platform.
JWT authenticator - should be generic as possible to support the JWT standard and any Vendor in the future. 

#### Class diagram
The following table represents all the configuration options i want to have in JWT and its comparison to GCP

|                                                                    |     JWT                                   |     GCP                                                                             |
|--------------------------------------------------------------------|-------------------------------------------|-------------------------------------------------------------------------------------|
|     api                                                            |     authn-jwt/                            |     authn-gcp/                                                                      |
|     Mandatory base claims to validate                              |     Iss, exp, nbf (Configurable)          |     iss, exp, iat (Constants)                                                       |                                  |
|     Optional base claims to validate (if exists in the token)      |     aud,sub,iat (Configurable)            |     -                                                                               |
|     provider-uri                                                   |     Configurable                          |     Constant                                                                        |
|     Public-certificate                                             |     Configurable (In case of self sign)   |     -                                                                               |
|     iss value                                                      |     Configurable   (list?)                |     Constant                                                                        |
|     aud value                                                      |     Configurable   (list?)                |     Constant                                                                        |
|     sub value                                                      |     Configurable   (list?)                |     -                                                                               |
|     Host   annotation prefix                                       |     authn-jwt                             |     authn-gcp                                                                       |
|     Permitted annotation keys                                      |     any                                   |     instance-name OR project-id OR   service-account-id OR service-account-email    |
|     Mapping host annotation logic                                  |     -                                     |     Map each above key   to his location in the google JWT token                    |

The following diagram represents JWT authenticator with a lot of small responsibility units, according to the above 
table and past experience, in order to have the flexibility to support future vendors that uses JWT token for their 
authentication process, like Google, GCP.

**Note:** in this feature we will support only GCP
![Authn gcp class diagram](authn-gcp-class-diagram.png)

GCP & JWT will have 3 dependencies which will change their behavior by dependency injection  

1. **Fetch Authenticator configuration**

    1.1 **Fetch provider uri**
    
    * GCP implementation - return an hardcoded
    * Authenticator policy implementation - fetch from provider uri value in the policy, this logic is relevant for: OIDC, Azure, JWT
    
    1.2 **Fetch claims**
        
      1.2.1 **Fetch mandatory claims keys to validate** - list of claims that must exist in token
        
      * GCP implementation - return an hardcoded list (Iss, exp, iat)
      * OIDC needs refactor - return an hardcoded list (Iss, exp, nbf)
      * Azure needs refactor - return an hardcoded list (Iss, exp, nbf)
      * JWT design phase - return an list which defined in a variable under the authenticator policy
      
      1.2.2 **Fetch mandatory claims values** - values of claims to validate which can be reside in different location: hardcoded, policy, hostname, uri of the request
      * GCP implementation - return an hardcoded values (Iss = "https://www.googleapis.com/oauth2/v1/certs", aud = "conjur"
      * OIDC needs refactor - fetch iss value from the provider uri 
      * Azure needs refactor - fetch iss value from the provider uri 
      * JWT design phase - return the values of mandatory claims from variable in policy
      
      1.2.3 **Fetch optional claims to validate** - list of claims that we should validate only if they appears in the token 
      * GCP - not relevant
      * OIDC - not relevant
      * Azure - not relevant
      * JWT design phase - return the values of optional claims from variable in policy
      
      1.2.4 **Fetch optional claims values**
      * JWT design phase - return the values of optional claims from variable in policy
      
      1.2.5 **authn prefix parameter** - the authenticator prefix which will later be use the fetch a the host annotations 

2. **Validate and decode** - same code a today with small refactoring of sending also the claims values if necessary 
    
    * Fetch public key
    * Validate signature
    * Validate claims
    * Save key in cache 

3. **Validate resource restrictions** - Responsible to validate the resource restrictions which defined in conjur, the idea is to refactor Azure and K8S to work with this pattern 
    
    3.1 **Extract Source Restrictions** 
    
    * Host annotations implementation  -  Fetch host annotations values, this logic is relevant to GCP, JWT, Azure, K8s
    
    3.2 **Validate Source Restrictions** - Each authenticator will have his special logic of which annotation are permitted  (In perfect world this logic should be trigger in load policy stage)
    
    * GCP implementation - validate GCP annotations logic (instance-name OR project-id OR service-account-id OR service-account-email)
    * Azure needs refactor - same Azure logic
    * K8s needs refactor - same K8S logic
    * JWT design phase - any key is permitted
    
    3.3 **Validate destination Restrictions** - In GCP,JWT,Azure we are validating against JWT token, in K8S against api 
      
      3.3.1 **Key Adapter** - Responsible of mapping source key to its corresponding destination key value 
    
    * GCP implementation - use a key adapter to find the corresponding key to validate
    * Azure needs refactor - same Azure xms_mirid logic
    * K8s needs refactor - same K8S logic
    * JWT design phase - straightforward validation 

#### GCP authenticator flow
![Authn gcp flow](authn-gcp-flow.png)


### Backwards compatibility
None because this is a new feature.

### Performance
GCP authenticator performance should conform with our other authenticators with an average call time of 1 second.

### Affected Components
- Conjur

- DAP

## Security
* **Future support in Service account key needs to be done very carefully** since there is a concern of impersonate other Conjur hosts, 
because the Service account key enable you to control the content of the JWT token. 
The reason it is not a concern in our use case, because we are validating only tokens which supplied by google metadata server, 
and signed by google private keys which are not expose to the apps in contrast to the Service account key.

* **Default token expiration is 1 hour** - we will stay with the default 

* **onetime** - Ori suggested to consider a mechanism to allow to each token to be used only once, 
but in this version we will not implement this capability  

## Test Plan
[Link to confluence](https://ca-il-confluence.il.cyber-ark.com/display/rndp/Conjur+GCP+authenticator+-+Test+plan#/) 

## Logs

### Error Log level

|    | Scenario                                                                | Log message                                                                            | Comment            |
|--- |-----------------------------------------------------------------------  |----------------------------------------------------------------------------------------|------------------------|
| 1  | Authenticator is not enabled (in DB/ENV)                                | Authenticator '{0-authenticator-name}' is not enabled                                  | |
| 2  | Webservice is not defined in a Conjur policy                            | Webservice '{0-webservice-name}' wasn't found                                          | |
| 3  | Host is not permitted to authenticate with the webservice               | '{0-role-name}' does not have 'authenticate' privilege on {1-service-name}             | |
| 4  | Host is not defined in Conjur                                           | '{0-role-name}' wasn't found                                                           | |
| 5  | Couldn't make connection with Google Identity Provider in time          | Google Identity Provider failed with timeout error (Provider URI: '{0}'). Reason: '{1}'| |
| 6  | Failed to confirm Google token signature                                | Failed to confirm signature of '{0-token}' issued by (Provider URI: '{1}'              | |
| 7  | Failed to validate Google token claims                                  | Will be decided in Impl phase              | |
| 8  | Authentication request body is missing a field (e.g `jwt_token`)        | Field '{0-field-name}' is missing or empty in request body                             | |
| 9  | A required annotation is missing in the Conjur host                     | Will be decided in Impl phase                                                          | Annotation is missing for authentication |
| 10 | Resource Restrictions includes an illegal constraints                   | Will be decided in Impl phase                                                          | Host contains an un permitted annotation |
| 11 | Resource Restrictions defined in Conjur host doesn't match JWT token    | Will be decided in Impl phase                                                          | The message should say to validate if the token issued with `Format=full`|


### Debug Log level

|    | Scenario                                              | Log message                                                                            | Comment             |
|--- |-------------------------------------------------------|----------------------------------------------------------------------------------------|-------------------------|
| 1  | Before each logic action                              | Will be decided in Impl phase                                                          | For example: fetch claims, validate token, validate resource ... |
| 2  | After each logic action                               | Will be decided in Impl phase                                                          |  |
| 3  | Value of configuration                                | Will be decided in Impl phase                                                          | For example: for example provider uri, claims ... |

### Audit 
Same logic like all other authenticators.

## Documentation
* Document examples of how to fetch google identity in GCP
* Document the solution supported use cases, logs and supportability section 


## Automation Design

### Introduction
We would like to add automated tests for the GCP Authenticator.
While Unit Tests are already automated, we will need to add some infrastructure for running integration tests.

### Scope
  - Run integration tests in OSS
  - Run a vanilla test in appliance
  - Run automation on a DAP image that is deployed on GCP (Manual at first stage, automation on POST GA)

### Run Integration Tests in OSS
GCP Authenticator tests will be added to the the general infrastructure of our integration test.
The integration will be supported both from `ci/test` script and `dev/start` the later will require creating GCP manually.
The integration test does not require creation of secrets.
The tests will cover [issuing an identity token](https://cloud.google.com/compute/docs/instances/verifying-instance-identity) 
in Google Compute Engine (GCP) and
presenting the issued token to Conjur's `host/authenticate` end point and exchange it with a valid Conjur token.

#### GCP Variables in Tests
- Non-sensitive
  - GCP project ID
  - GCE instance name
  - GCP Service Account ID
  - GCP Service Account email
- Sensitive
  - GCP VM IP / dns name
  - user name
  - ssh key
 
Although the non-sensitive data can be hard-coded, it is better to store them as Conjur secrets as we already need 
summon for the sensitive data. This way if they need rotation it can be easily done in Conjur without the need to 
update the code-base. 
 
To do so, we will need to add a "secrets.yml" with the variables and run the scripts ("ci/test" and in "dev/start") 
with summon. However, we will not just start running these scripts with summon to run the current tests just they the 
authn-cp tests can run as part of their run. If we do that, then users from the community will not be able to run 
the authenticators tests (because they don't have access to ``conjurops``).

Thus it is better to run the integration tests separately from the other authentication tests. 
We will add a new step to the Jenkinsfile for running the tests.
```
stage('Run Tests') {
  parallel {
    ...
    stage('Authenticators') {
      steps { sh 'ci/test cucumber_authenticators' }
    }
    stage('GCP Authenticator') {
      steps { sh 'summon ci/test cucumber_gcp_authenticator' }
    }
    ...
  }
}
```
For the "dev/start" script we can verify that if the "--authn-gcp" flag was added then the required variables were 
retrieved, and raise an "GCP tests must run with summon" message. 

Please note that we will need to add a new flag to the "ci/test" script - "cucumber_gcp_authenticator" as it will 
need summon.

### GCP for Tests
We need to have an GCE instance for our tests to generate a GCP identity access token. For this, we will use a [Jenkins 
plugin for GCP](https://plugins.jenkins.io/google-compute-engine)) that allows to deploy instances of GCP VMs which 
are provisioned quickly, and get destroyed by Jenkins when idle. 
This way the cost in minimal, we don't have concurrency issues and we don't need to maintain an IP in our secrets for 
the VM IP addresses.

The new Jenkinsfile will look as follows:
```
stage('Allocate GCP Authenticator Instance'){
  steps {
    script {
      node('gcp-authn'){
        env.GCP_AUTHN_INSTANCE_IP = sh(script: 'curl icanhazip.com', returnStdout: true)
        env.KEEP_GCP_AUTHN_INSTANCE = "true"
        while(env.KEEP_GCP_AUTHN_INSTANCE == "true"){
          sleep(time: 1, unit: "SECONDS")
        }
      }
    }
  }
}
stage('Test GCP Authenticator'){
  steps{
    script {
      while (!env.GCP_AUTHN_INSTANCE_IP?.trim()){
        sleep(time: 1, unit: "SECONDS")
      }
      sh(
        script: 'summon -f ci/authn-gcp/secrets.yml ci/test cucumber_authenticators_gcp',
        returnStdout: true
      )
    }
  }
  post {
    always {
      script {
        env.KEEP_GCP_AUTHN_INSTANCE = "false"
      }
    }
  }
}
```
As you can see, we have a stage that allocates the GCP VM and sets its IP in the env. That IP is then consumed from 
the env in the GCP Authenticator tests. Once the tests are finished, we update KEEP_GCP_AUTHN_INSTANCE and the 
GCP VM allocation stage is finished.

### Run authn-gcp Requests
To get a Conjur access token with an GCP identity token we need to issue a GCP identity token first.

#### Issue GCP Identity token
Send an authn-gcp request to Conjur with the [GCP identity token](https://cloud.google.com/compute/docs/instances/verifying-instance-identity)
in the body. In production, both actions will be done inside a GCE instance.
However, in our tests, it will be much easier to perform only the first action inside a GCE instance and perform the second 
action from the cucumber container. This way will only need to add a step for SSHing to a remote machine and send the 
command for retrieving an access token. We already have the infrastructure and the code for sending an authentication 
request to the server.

The test verifies that Conjur authenticates a valid Google identity token and get Conjur access token as a result. 
The only thing that we don't test here is the communication between the GCP machine to Conjur server but it's 
acceptable for 2 reasons:
- The test is done manually.
- Even if we do test communication in our automation, it doesn't guarantee that there will not be any errors in the 
customer's env.

The two reasons above brings us to the conclusion that running the authentication request from outside the GCP machine 
has the same quality of running it inside the machine.

### Requirements from DevOps
- GCP VM for tests
- Secrets in `conjurops`
  - GCP project id
  - GCE instance name
  - Service account id
  - Service account email
  - Machine IP
  - user id / ssh key
  
### Version update
TODO: Inbal to decide which versions?

- Conjur

- DAP

## Open questions
- Authenticator name may change `authn-gcp` ? TODO: Inbal to decide 

## Implementation plan

**Merging to master strategy**

In this feature we are prefer to work with a feature branch instead of small PRs to master,
Since we are planning to deliver it before the planned release version.

Pros:
We will have more flexibility to any change of release date and its quality (GA or CA)

Cons:
More complex merge back to the master


### Total EE44
**Parallelism:** The feature can be paralleled to 3 team members all the way

#### Ramp up EE0
already covered in research phase

#### Designs EE0
None.
Note: LLD designs need will be decided at implementation level 

#### POC and researches EE3
1. JWT 3rd party validation - Use our JWT 3rd lib to authenticate a google JWT token, with the following claims: iss, aud, exp, nbf, iat
   Raise a concerns if any **EE2** 
2. Instigate in which scenarios the following google JWT token field is false  `email_verified": true` ? do we need a special treatment there ? **E1**

#### Implementation EE15
1. Implement classes according to design and write LLD where is needed

    1.1. 6 classes - EE2 for implement each plus UT **EE12**
2. Implement status validation **EE1**
3. Enhance logs and supportability **EE1**
4. Release from side branch **E1**

    4.1 Merge stable released Conjur to our side branch
    4.2 Update Conjur and DAP versions 
    4.3 Release DAP as CA from side branch 
5. Implement user extraction for aud claim indie the token **E1**

#### Testing EE19
1. Automation infrastructure 

    1.1. OSS - Create GCE instance **EE1**
    
    1.2. OSS - Issue an identity token **EE1**
    
    1.3. DAP - Create GCE instance **EE1**
    
    1.4. DAP - Issue an identity token **EE1**
        
2. OSS - Implement integration tests **EE5**
3. DAP - Implement integration tests for **EE3**
4. Manual tests according to docs (customer env) **EE1**
5. Performance tests **EE3**
6. Setting customer env **EE2**

    6.1 1 Master and 2 standbys outside GKE according to our [docs](https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Integrations/Kubernetes_Implementations.htm?tocpath=Integrations%7COpenShift%252C%20Kubernetes%7C_____1)
    
    6.2 2 Followers inside GKE with LB
    
    6.3 1 GCP client machine 
7. Support GCP in dev/start script **EE1**

#### Security EE2
1. Review EE2 

#### Docs EE4 
1. Document examples of how to fetch google identity in GCP **EE2**
2. Document the solution supported use cases, logs and supportability section **EE2**

    2.1 Require a `"format=full" ` parameter when issuing the google identity token, in order to have the `compute_engine` 
    structure which contains the metadata on the GCP machine
    
    2.2 Recommend not to use google default service account in production 

### Post GA EE6 + ??
#### Testing
1. Infrastructure to deploy DAP image on GCP

#### Designs  
1. LLD for K8S, Azure ang GCP to use same component of ValidateResourceRestrictions class **EE3**

#### Implementation
1. Implement LLD1 **EE3**

#### Testing
1. Automated Left over tests**EE??**

### Implement JWT authenticator as Beta EE18
#### Designs  
1. Validate again the HLD **EE2**

#### Implementation
1. Implement JWT authenticator according to design **EE10**
2. Implement status validation **EE1**
3. Enhance logs and supportability **EE1**

#### Security EE2
1. Review EE2 

#### Testing
1. Only manual unless we will decide to release it as CA or GA  **EE2**

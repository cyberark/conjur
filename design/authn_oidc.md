**Note: This feature is developed as a POC**

**Note**: This design document has been ported from the original document
[here](https://github.com/cyberark/conjur/issues/838).

# Feature Overview & Customer Need
The customer, would like to following flow to work:

An app user logging on to the app portal or through PSMP, going through a OIDC authentication process implemented by the app connecting to an OIDC provider. The app retrieves an ID token or an OAuth access token of the user in which an ID token exists.

The app connects to other applications\services which are involved in the main application flows and would like to be able to leverage the token acquired from the portal in order to login to Conjur and retrieve secrets.

Conjur should provide an authentication web service that will get as an input the ID token then it will
- Validate the ID token
- Understand the user’s Conjur identity and based on a predefined policy what permissions the user has
- Provide the right Conjur access token with which the secret is retrieved and other Conjur actions are made.

In Summary, Conjur will provide an ID Token authenticator is a new authenticator which authenticate users using their ID token against OIDC provider and then returns their Conjur identity.

# Process Diagram
![image](https://user-images.githubusercontent.com/26732770/51806128-afabb400-227e-11e9-9afe-dcef2d329ca4.png)
**Process Logic \ XDD**
**Configuration in OIDC provider**

- IT\Infosec  registers the Conjur application with OIDC provider to obtain a client ID, client secret and org. Described here for Okta as an example.

- IT\Infosec enrolls some of the users to use different factors if at all, described here for Okta as an example.

# Set up the identity provider authenticator in Conjur
 - Conjur admin\Infosec adds the identity provider (Okta) URL to Conjur policy with client ID, client secret, and org as variables.
Another variable called "IDTokenUserProperty" will be set with the name of the property in the ID Token by which we will map the user name in Conjur
```
-!policy
 id:conjur/authn-oidc/okta/

 body:
 -!webservice
   annotations:
     description:Authentication service for Okta, based on Open ID Connect.

    - !variable
      id: provider-uri #Okta uri

    - !variable
      id: id-token-user-property #value for example: preferred_username

   -!group
     id: okta-users
     annotations:
      description:  
        Roles authorized to use the authn-oidc/okta webservice. Usually has a layer member which contains enrolled applications.

  -!permit
    resource: !webservice
    privilege: [ read, authenticate ]
    role: !group okta-users
```

-  In the following example we will assume that a user named alice is part of LDAP users that were assigned also to okta-users. Alternatively, the flow could be applicable also for hosts

 - Enable the authn-oidc authenticator by setting the CONJUR_AUTHENTICATORS environment variable. For example: CONJUR_AUTHENTICATORS=authn-oidc/okta

# Configure secrets with permissions to some okta users
A policy with vars /JIRA-frontend/JIRAOracleDB/username & /JIRA-frontend/JIRAOracleDB/password and permissions to alice to read and execute. These vars was deployed by JIRA Conjur admin. The values were added to the vars.
```
`- !policy
  id: JIRA-frontend
  annotations:
    description: the JIRA microservice that is responsible for user interaction
  body:
  - &variables
    - !variable JIRAOracleDB/username
    - !variable JIRAOracleDB/password
  - !permit
    role: !user alice
    privilege: [ read, execute ]
    resource: *variables`
```

# User is identified through an Open ID protocol

- Alice is connected to App (in our case JIRA) that redirect her to identify herself in an  Open ID protocol.
- The APP gets hold of the ID Token of Alice.
- It uses this ID Token to connect with other parties like other App microservices.

**App connects to Conjur to retrieve secrets**

- App calls authn-oidc/okta/  to login with Alice ID Token in return it get Conjur access token.
- Conjur knows how to map the ID Token to it's user in Conjur and also verify the correctness of the ID Token against the ID provider.
- With this access token is retrieves vars /JIRA-frontend/JIRAOracleDB/username & /JIRA-frontend/JIRAOracleDB/passwordAssumptions

- The app microservice knows how to refresh the OAuth access token and ID token on her own.

# User experience flow for **POC**

1. OIDC Configuration
- Enable the authn-oidc authenticator by setting the CONJUR_AUTHENTICATORS environment variable. For example: CONJUR_AUTHENTICATORS=authn-authn-oidc/adfs
- Load a policy which defined the authn-oidc authenticator according to feature doc which contains the Conjur Client ID & Secret in ADFS (oidc provider)
- Create a Conjur user which known to ADFS and has permission to oidc authenticator
- Assumption: The user is defined in the root policy
2. Given I have an ID Token
- Application has as ID Token of user that already authenticate through ADFS
- The ID Token contains the email of the user
3. Authenticate based on ID Token
- App access Conjur authn-oidc authenticate api and sending the id_token
- authn-oidc validate the ID Token
- Identify the user
- return Access token to Conjur

## Design
[ID Token as an authentication method in Conjur (1).pdf](https://github.com/cyberark/conjur/files/2828986/ID.Token.as.an.authentication.method.in.Conjur.1.pdf)


# Open Issues
How to map Conjur users\hosts to OIDC provider users\hosts?


# Support
This feature will be developed as a **POC** only

# Research
## DOD
- Research page with all info regarding OIDC App 2 App HLD\Research result
- Test plan written and reviewed by PO & QAA
- Security review was done and issues were raised
- Research results presented and shared
- High level effort estimations and risks

## Implementation First Phase- internal mapping mechanism
We will start implementation with an internal mapping mechanism that has the following assumptions:
1. The field in the ID token is email.
2. The email will map to a username of a root user in Conjur

## Demo
1.  Configuration in OIDC provider
2.  Set up the identity provider authenticator in Conjur
3.  Enable the authn-oidc authenticator by setting the CONJUR_AUTHENTICATORS environment variable.
4.  Configure secrets with permissions to some oidc users
5.  Alice is connected to App (in our case JIRA) that redirect her to identify herself in an  Open ID protocol.
6.  The APP gets hold of the ID Token of Alice.
7.  It uses this ID Token to connect with other parties like other App microservices.
8.  App connects to Conjur to retrieve secrets
9.  App calls authn-oidc/okta/  to login with Alice ID Token in return it get Conjur access token.
10.  Conjur knows how to map the ID Token to it's user in Conjur and also verify the correctness of the ID Token against the ID provider.
11.  With this access token is retrieves vars /JIRA-frontend/JIRAOracleDB/username & /JIRA-frontend/JIRAOracleDB/passwordAssumptions
12. The app microservice knows how to refresh the OAuth access token and ID token on her own.

## DOD
- Implement an OIDC authn for App 2 App scenario with internal mapping
- Automatic integration tests written according to a test plan and passed successfully
- UT written for all classes\functions\major logic flows and passed successfully
- Security review was done
- Security action items were taken
- Performance tests were done - no performance regression has been made
- Supportability tasks were written in OIDC App 2 App supportability page
- Enhance logs and supportability according to guidelines in Supporting+ID+Token+as+an+authentication+method+in+Conjur#SupportingIDTokenasanauthenticationmethodinConjur-Logs&AuditGuidelines
- Fill in the logs in the feature doc
- Logs were reviewed by TW and PO
- Fill in the configurations in the feature doc
- Configurations were reviewed by PO
- Documentation HO to TW and review docs


# Delivery plan

## Debts from Okta integration
- Research - self sign issue (more details: ONYX-1779)
- Dev - Base on self sign research decision
- Dev - Refactoring strategy
- Dev - Change previous OKTA APIs and adapt scripts and automations env
- Testing - UT Infrastructure rspec

## Infrastructure and others
- Plan - Design test app and running environment for ID token authenticator
- Plan - summarize Okta integration for future use
- Research - Dev environment to test ADFS
- Research - ID Token validation ( only check if active=true?, claims?)
- Research - Do i have issues with authenticator and Conjur Env (satellite and one master), Design wise and search for open issues in Conjur
- Research - Check if LDAP sync working with email as a user name
- Dev - Change the start script to create a proper dev env for this feature
- Testing - Automation env to run against s ADFS or using key cloak ?

## Implementation
- Dev end to end flow with hardcoded email as Conjur user in root policy
- Dev - ID Token is validated
- Verify Logs and error handling in OIDC flow
- Fixes/Surprises form previous Okta feature (Like the error in audit before identifying the User)
-  Prepare OIDC code for next iteration
- User can modify the id token property to link to Conjur username
 
## Testing
- Write test plan
- Retrieve ID Token from keycloak in script
- Open Source - run manual tests according to test plan
- Production env - run tests according to test plan
- Create automated tests according to test plan

## Docs
- Write docs
- Create PDF for oidc docs
- Add authentication main page to OIDC PDF

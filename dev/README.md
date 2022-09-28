# Conjur Development

## Jenkins

To start a development environment with Jenkins (and JWT authentication), run `start` with the `--jenkins` flag:

```
./start --jenkins`
```

After the setup script has completed, you'll be dropped into a shell in the Conjur container. Start Conjur with the following command:

```
rails s -u webrick -b 0.0.0.0
```

### Configure Jenkins

#### Setup

1. Navigate to Jenkins running on port `9090`: http://localhost:9090.
2. Retrieve the initial admin password by navigating to the file `jenkins_custom_volume/secrets/initialAdminPassword`.  Copy the value, and past it into the Jenkins login screen, and click `Continue`.
3. Select "Install suggested plugins", and wait for plugins to be installed.
4. Update the `admin` user password to something you'll remember (ex. `Jenkins`).  You'll need to fill in a name and email address as well.
5. On the "Instance Configuration" page, click "Save and Finish".
6. Click "Start using Jenkins"

#### Create a Job

1. On the home page, click "New Item" (top of upper left navigation)
2. Enter `test-pipeline` in the item name box.  Select "Pipeline", and click "OK".
3. Under the "Pipeline" header, insert the following:
    ```
    node {
      stage('Work') {
        withCredentials([conjurSecretCredential(credentialsId: 'SECRET_1', variable: 'SECRET')]) {
          echo "Hello World $SECRET"
        }
      }
      stage('Results') {
        echo 'Finished!'
      }
    }
    ```
4. Click "Dashboard" from the upper left breadcrumb menu to return to the home dashboard.

#### Install and Configure Conjur Plugin

1. Click "Manage Jenkins" from the left menu.
2. Click "Manage Plugins".
3. Click "Available" and search for Conjur. Click the checkbox next to "Conjur Secrets" and click "Install without restart".
4. Scroll down to the bottom of the page.  Once the installation is complete, click "Go back to the top page".
5. Click "Manage Jenkins" from the left menu.
6. Click "Configure System".
7. Scroll down to the `Conjur Appliance` header.  Set `Account` to `cucumber`.  Set `Appliance URL` to `http://conjur:3000`.
8. Scroll down to the `Conjur JWT Authentication` header.
   1. Check "Enable JWT Key Set Endpoint" checkbox.
   2. Set "Auth Webservice ID" to `jenkins` (this is the name of the Conjur JWT authenticator for this Jenkins instance).
   3. Set "JWT Audience" to `jenkins-projects` (needs to match the authenticator `audience`).
   4. Check "Enable Context Aware Credential Stores?" checkbox.
   5. Set "Identity FieldName" box to `identity`.
   6. Set "Identity Format Fields" box to `jenkins_full_name`.
   7. Click "Save" to save settings.

#### Populate Credential Store
1. From the Home Page, click "Manage Jenkins".
2. Click "Configure System".
3. Scroll down to the `Conjur Appliance` header. Click the `Refresh Credential Store` button.
4. Click "Save" button.
5. Click "test-pipeline" pipeline.
6. Click "Credentials" at the bottom of the left menu.

You should now see two credentials:

- `jenkins-secrets-secret-1`
- `jenkins-secrets-secret-2`

#### Create a Jenkins Secret

1. From the Home Page, click "Manage Jenkins".
2. Click "Manage Credentials".
3. Click "(global)" under the "Domain" column.
4. Click "Add Credentials".
   1. Under "Kind" dropdown, select `Conjur Secret Credential`.
   2. In "Variable Path" input, put `jenkins-secrets/secret-1`.
   3. In "ID" input, put `SECRET_1`.
5. Click "Create"
6. Navigate to the `test-pipeline` job and click "Build Now". If everything was correctly configured, the pipeline should be green.


## Authenticators

### JWT Authenticator

JWT Authentication offers a mechanism for mapping the claims on a JWT certificate to an identity in Conjur. Setup can be confusing, so always start with the JWT. The following is a set of JWT claims from the Jenkins Plugin:

```json
{
  "sub": "admin",
  "jenkins_full_name": "test-pipeline",
  "iss": "http://localhost:9090",
  "aud": "jenkins-projects",
  "jenkins_name": "test-pipeline",
  "nbf": 1664300708,
  "identity": "test-pipeline",
  "name": "Admin User",
  "jenkins_task_noun": "Build",
  "exp": 1664300858,
  "iat": 1664300738,
  "jenkins_pronoun": "Pipeline",
  "jti": "c86322f29bff475ab8cd78c1a1188d68",
  "jenkins_job_buildir": "/var/jenkins_home/jobs/test-pipeline/builds"
}
```

**Note**: In the above set of claims:

- The `aud` (Audience) value is set by the `JWT Audience` setting in the "Conjur JWT Authentication" setting in the Conjur Plugin.
- The `identity` claim is defined in the `Identity Field Name` setting in the "Conjur JWT Authentication" setting in the Conjur Plugin. This claim's value is a composite value based on the `Identity Format Fields` and `Identity Fields Separator` values.

A JWT Authenticator requires the following variables:

- `token-app-property` - defines the claim value to be used as the primary identifier.
- `identity-path` - defines the Conjur policy the corresponding host is in.
- `issuer` - defines the JWT issuer (the expected `iss` claim value).
- `audience` - defines the JWT audience (the expected `aud` claim value).
- `jwks-uri` - defines the URI of the JWT JWKS endpoint.

#### Host Definition

In addition, the Conjur host id MUST match claim defined in the Conjur variable `token-app-property`.  In the above example, if:

```
token-app-property = 'identity'
```

then the Conjur host MUST be:

```yml
- !host test-pipeline
```

Additionally, host annotations can be used to further match JWT claims.  For example, if we wanted to additionally limit the Conjur Host to only work for Pipeline jobs, we'd set the host as follows:

```yml
- !host
  id: test-pipeline
  annotations:
    authn-jwt/jenkins/jenkins_pronoun: Pipeline
```

**Note**: annotations can't be updated on an existing host. The host must be replaced.

#### Example

##### Authenticator

The following is a sample authenticator policy:

```yml
- !policy
  id: conjur
  body:
  - !policy
    id: authn-jwt
    body:
    - !policy
      id: jenkins
      body:
      # Authenticator Webservice
      - !webservice

      - !variable token-app-property
      - !variable identity-path
      - !variable issuer
      - !variable audience
      - !variable jwks-uri

      # Group of hosts that can authenticate using this authenticator
      - !group authenticatable

      # Permit the authenticatable group to authenticate to this authenticator web service
      - !permit
        role: !group authenticatable
        privilege: [ read, authenticate ]
        resource: !webservice

      ## -- Status Service --
      # Create a web service for checking the status of this authenticator
      - !webservice
        id: status

      # Group of users who can check the status of this authenticator
      - !group
        id: operators
        annotations:
          description: Group of users that can check the status of the authn-jwt/jenkins authenticator.

      # Permit group to check the status of this authenticator
      - !permit
        role: !group operators
        privilege: read
        resource: !webservice status
```

##### Pipeline hosts

```yml
- !policy
  id: jenkins-pipelines
  body:
  - !host
    id: test-pipeline
    annotations:
      authn-jwt/jenkins/jenkins_pronoun: Pipeline
```

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

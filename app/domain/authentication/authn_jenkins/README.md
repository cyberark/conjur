# authn-jenkins
Authenticate jenkins jobs without api keys.

### Prerequistes
1. Conjur server
2. Jenkins server


## Setup
### Conjur
1. Make sure the environment variable is set on the conjur server ```CONJUR_AUTHENTICATORS=authn-jenkins/prod```.
2. Log into conjur cli
3. Create a file called ```policy.yml``` with the contents of:
```yaml
- !policy
  id: conjur/authn-jenkins/prod
  body:
  - !webservice
  - !group clients
  
  # these will be used to connect to the jenkins server and see if a specific job is running
  - !variable jenkinsURL
  - !variable jenkinsUsername
  - !variable jenkinsPassword
  - !variable jenkinsCertificate

  # create a group that can authenticate to this jenkins instance
  - !permit
    role: !group clients
    privilege: [ read, authenticate ]
    resource: !webservice
```
4. Execute ```conjur policy load root policy.yml```. Now the authenticator is configured.
5. Create a file called ```job.yml``` (in this case the job will be called 'testJob' within jenkins) with the contents of:
```yaml
---
# This is creating a policy for 'team1' that has 1 jenkins job of 'testJob'
# This jenkins job will have access to the 'team1/secret' secret.
- !policy
  id: team1
  body:
  - !host testJob
  - !variable secret
  
  - !permit
    role: !host testJob
    resources:
    - !variable secret
    privilege: [ read, execute ]

# This is giving the jenkinsJob the ability to authenticate as a jenkins job
- !grant
  role: !group conjur/authn-jenkins/prod/clients
  member: !host team1/testJob
```
6. Execute ```conjur policy load root job.yml```. Now 'testJob' will have the ability to authenticate without an API key and will use the jenkins authenticator.
7. Execute ```conjur variable values add team1/secret "someSecret"``` to populate the secret with a dummy value

### Jenkins
1. Import the [Jenkins Conjur Credential Plugin](https://github.com/AndrewCopeland/conjur/blob/master/dev/files/authn-jenkins/conjur-jenkins-plugin.hpi). Once the file has been downloaded upload it into your jenkins server by following: Jenkins Home -> Configure -> Plugin Manager -> Advanced -> Upload Plugin -> Choose File -> conjur-jenkins-plugin.hpi
2. Create a service account for this jenkins instance. (Remember the username and password since it will be used in a future step #4)
3. Setup the jenkins authentication URL. Execute ```conjur variable values add conjur/authn-jenkins/prod/jenkinsURL "http://<jenkinsURL>:<jenkinsPort>"```
4. Setup the jenkins authentication service account credentials. Execute ```conjur variable values add conjur/authn-jenkins/prod/jenkinsUsername "<serviceAccountUsername>"``` & ```conjur variable values add conjur/authn-jenkins/prod/jenkinsPassword "<serviceAccountPassword>"```
5. Create a folder in jenkins called ```team1```.
6. Within this folder create a pipeline called ```testJob```.
7. Uncheck ```Inherit for parent?```
8. Check ```Use Just-In-Time --JIT-- Secret Access```
9. Set ```Auth WebService ID``` to ```prod```
10. Skip ```Host Authentication Prefix```
11. Set ```Account``` to ```cucumber``` or the account you configured conjur with
12. Set ```Appliance URL``` to ```http://<conjur-ip-or-hostname>:<port>```. It should look like:


13. Scroll down and set your ```Pipeline Script``` to:
```
node {
   stage('Work') {
      withCredentials([conjurSecretCredential(credentialsId: 'SECRET_ID', 
                                              variable: 'SECRET')]) {
         echo "Hello World $SECRET"
      }
   }
   stage('Results') {
      echo "Finished!"
   }
}
```
14. In the pipeline we are fetching our conjur credential by ID ```SECRET_ID```.
15. Navigate to the Jenkins main page and select ```Credentials```
16. Select ```Add Credentials```
17. Set kind to ```Conjur Secret Credential```
18. Set ```Variable Path``` to ```team1/secret```
19. Set ```ID``` to ```SECRET_ID```
20. It should look like:

21. Now run the job and it should fetch the secret successfully. When looking at the job console the password should be scrubbed automatically

```


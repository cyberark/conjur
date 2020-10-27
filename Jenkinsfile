#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
    timeout(time: 1, unit: 'HOURS')
  }

  triggers {
    parameterizedCron(getDailyCronString("%NIGHTLY=true"))
  }

  parameters {
    booleanParam(name: 'NIGHTLY', defaultValue: false, description: 'Run tests on all agents and environment including: FIPS')
  }

  stages {
    stage('Fetch tags') {
      steps {
        withCredentials(
          [usernameColonPassword(credentialsId: 'conjur-jenkins-api', variable: 'GITCREDS')]
        ) {
          sh '''
            git fetch --tags `git remote get-url origin | sed -e "s|https://|https://$GITCREDS@|"`
            git tag # just print them out to make sure, can remove when this is robust
          '''
        }
      }
    }

    stage('Validate') {
      parallel {
        stage('Changelog') {
          steps { sh 'ci/parse-changelog' }
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh './build.sh --jenkins'
      }
    }

    stage('Scan Docker Image') {
      parallel {
        stage("Scan Docker Image for fixable issues") {
          steps {
            script {
              TAG = sh(returnStdout: true, script: 'echo $(< VERSION)-$(git rev-parse --short=8 HEAD)')
            }
            scanAndReport("conjur:${TAG}", "HIGH", false)
          }
        }
        stage("Scan Docker image for total issues") {
          steps {
            script {
              TAG = sh(returnStdout: true, script: 'echo $(< VERSION)-$(git rev-parse --short=8 HEAD)')
            }
            scanAndReport("conjur:${TAG}", "NONE", true)
          }
        }
      }
    }

    stage('Prepare For CodeClimate Coverage Report Submission'){
      steps {
        script {
          ccCoverage.dockerPrep()
          sh 'mkdir -p coverage'
        }
      }
    }

    stage('Run environment tests in parallel') {
      parallel {
        stage('EE FIPS agent tests') {
            agent { label 'executor-v2-rhel-ee' }
            when {
                beforeAgent true
                expression { params.NIGHTLY }
            }
            steps {
              script {
                 parallel([
                    "RSpec - ${env.STAGE_NAME}": {
                      sh 'ci/test rspec'
                    },
                    "Authenticators Config - ${env.STAGE_NAME}": {
                      sh 'ci/test cucumber_authenticators_config'
                    },
                    "Authenticators Status - ${env.STAGE_NAME}": {
                      sh 'ci/test cucumber_authenticators_status'
                    },
                    "LDAP Authenticator - ${env.STAGE_NAME}": {
                      sh 'ci/test cucumber_authenticators_ldap'
                    },
                    "OIDC Authenticator - ${env.STAGE_NAME}": {
                      sh 'ci/test cucumber_authenticators_oidc'
                    },
                    "Policy - ${env.STAGE_NAME}": {
                      sh 'ci/test cucumber_policy'
                    },
                    "API - ${env.STAGE_NAME}": {
                      sh 'ci/test cucumber_api'
                    },
                    "Rotators - ${env.STAGE_NAME}": {
                      sh 'ci/test rspec'
                    },
                    "Kubernetes 1.7 in GKE - ${env.STAGE_NAME}": {
                      sh 'cd ci/authn-k8s && summon ./test.sh gke'
                    },
                    "Audit - ${env.STAGE_NAME}": {
                      sh 'ci/test rspec_audit'
                    }
                 ])
              }
              stash name: 'testResultEE', includes: "cucumber/*/*.*,container_logs/*/*,spec/reports/*.xml,spec/reports-audit/*.xml,cucumber/*/features/reports/**/*.xml"
            }
          } // EE FIPS agent tests

        stage('Standard agent tests') {
          steps {
            script {
               parallel([
                  "RSpec - ${env.STAGE_NAME}": {
                    sh 'ci/test rspec'
                  },
                  "Authenticators Config - ${env.STAGE_NAME}": {
                    sh 'ci/test cucumber_authenticators_config'
                  },
                  "Authenticators Status - ${env.STAGE_NAME}": {
                    sh 'ci/test cucumber_authenticators_status'
                  },
                  "LDAP Authenticator - ${env.STAGE_NAME}": {
                    sh 'ci/test cucumber_authenticators_ldap'
                  },
                  "OIDC Authenticator - ${env.STAGE_NAME}": {
                    sh 'ci/test cucumber_authenticators_oidc'
                  },
                  "Policy - ${env.STAGE_NAME}": {
                    sh 'ci/test cucumber_policy'
                  },
                  "API - ${env.STAGE_NAME}": {
                    sh 'ci/test cucumber_api'
                  },
                  "Rotators - ${env.STAGE_NAME}": {
                    sh 'ci/test rspec'
                  },
                  "Kubernetes 1.7 in GKE - ${env.STAGE_NAME}": {
                    sh 'cd ci/authn-k8s && summon ./test.sh gke'
                  },
                  "Audit - ${env.STAGE_NAME}": {
                    sh 'ci/test rspec_audit'
                  }
               ])
           }
          }
        } // Standard agent tests

        stage('Azure Authenticator') {
          steps {
            script {
              node('azure-linux') {
                // get `ci/authn-azure/get_system_assigned_identity.sh` from scm
                checkout scm
                env.AZURE_AUTHN_INSTANCE_IP = sh(script: 'curl "http://checkip.amazonaws.com"', returnStdout: true).trim()
                env.SYSTEM_ASSIGNED_IDENTITY = sh(script: 'ci/authn-azure/get_system_assigned_identity.sh', returnStdout: true).trim()

                sh('summon -f ci/authn-azure/secrets.yml ci/test cucumber_authenticators_azure')
              }
            }
          }
        }
        /**
        * We have 3 stages for GCP Authenticator tests.
        * In this stage, a GCE instance node is allocated, a script runs and retrieves all the tokens that will be
        * used in authn-gcp tests.
        * The token are stashed, and later un-stashed and used in the stage that runs the GCP Authenticator tests.
        * This way we can have a light-weight GCE instance that has no dependency on conjurops
        * or git identities and is not open for SSH.
        */
        stage('GCP Authenticator preparation - Allocate GCE Instance') {
          steps {
            echo '-- Allocating Google Compute Engine'
            script {
              dir('ci/authn-gcp') {
                stash name: 'get_gce_tokens_script',
                includes: 'get_gce_tokens_to_files.sh,get_tokens_to_files.sh,tokens_config.json'
              }
              node('executor-v2-gcp-small') {
                echo '-- Google Compute Engine allocated'
                echo '-- Get compute engine instance project name from Google metadata server.'
                env.GCP_PROJECT = sh (
                    script: 'curl -s -H "Metadata-Flavor: Google" \
                    "http://metadata.google.internal/computeMetadata/v1/project/project-id"',
                    returnStdout: true
                ).trim()
                unstash 'get_gce_tokens_script'
                sh './get_gce_tokens_to_files.sh'
                stash name: 'authnGceTokens', includes: 'gce_token_*', allowEmpty:false
              }
            }
          }
          post {
           failure {
            script {
              env.GCP_ENV_ERROR = "true"
            }
           }
           success {
            script {
              env.GCE_TOKENS_FETCHED = "true"
            }
            echo '-- Finished fetching GCE tokens.'
           }
          }
        }
        /**
        * We have 3 stages for GCP Authenticator tests.
        * In this stage, Google SDK container executes a script to deploy a function,
        * the function accepts audience in query string and returns a token with that audience.
        * All the tokens required for testings are obtained and written to function directory, the post stage branch
        * deletes the function.
        * This stage depends on stage: 'GCP Authenticator preparation - Allocate GCE Instance' to set
        * the GCP project env var.
        */
        stage('GCP Authenticator preparation - Allocate Google Function') {
          environment {
            GCP_FETCH_TOKEN_FUNCTION = "fetch_token_${BUILD_NUMBER}"
            IDENTITY_TOKEN_FILE = 'identity-token'
            GCP_OWNER_SERVICE_KEY_FILE = "sa-key-file.json"
          }
          steps {
            echo "Waiting for GCP project name (Set by stage: 'GCP Authenticator preparation - Allocate GCE Instance')"
            timeout(time: 10, unit: 'MINUTES') {
              waitUntil {
                script {
                  return (env.GCP_PROJECT != null  || env.GCP_ENV_ERROR == "true")
                }
              }
            }
            script {
              if (env.GCP_ENV_ERROR == "true") {
                error('GCP_ENV_ERROR cannot deploy function')
              }

              dir('ci/authn-gcp') {
                sh 'summon ./deploy_function_and_get_tokens.sh'
              }
            }
          }
          post {
            success {
              echo "-- Google Cloud test env is ready"
              script {
                env.GCP_FUNC_TOKENS_FETCHED = "true"
              }
            }
            failure {
              echo "-- GCP function deployment stage failed"
              script {
                env.GCP_ENV_ERROR = "true"
              }
            }
            always {
              script {
                dir('ci/authn-gcp') {
                  sh '''
                  # Cleanup Google function
                  summon ./run_gcloud.sh cleanup_function.sh
                  '''
                }
              }
            }
          }
        }
        /**
        * We have two preparation stages before running the GCP Authenticator tests stage.
        * This stage waits for GCP preparation stages to complete, un-stashes the tokens created in
        * stage: 'GCP Authenticator preparation - Allocate GCE Instance' and runs the gcp-authn tests.
        */
        stage('GCP Authenticator - Run tests') {
          steps {
            echo 'Waiting for GCP Tokens. (Tokens are provisioned by GCP Authenticator preparation stages.)'
            timeout(time: 10, unit: 'MINUTES') {
              waitUntil {
                script {
                  return ( env.GCP_ENV_ERROR == "true"
                    || (env.GCP_FUNC_TOKENS_FETCHED == "true" && GCE_TOKENS_FETCHED == "true"))
                }
              }
            }
            script {
              if (env.GCP_ENV_ERROR == "true") {
                error('GCP_ENV_ERROR: cannot run tests check the logs for errors in GCP stages A and B')
              }
            }
            script {
              dir('ci/authn-gcp/tokens') {
                unstash 'authnGceTokens'
              }
              sh 'ci/test cucumber_authenticators_gcp'
            }
          }
        }
      }
    }

    stage('Submit Coverage Report'){
      steps{
        sh 'ci/submit-coverage'
      }
    }

    stage('Push Docker image') {
      steps {
        sh './push-image.sh'
      }
    }

    stage('Build Debian package') {
      steps {
        sh './package.sh'
        archiveArtifacts artifacts: '*.deb', fingerprint: true
      }
    }

    stage('Publish Debian package'){
      steps {
        sh './publish.sh'
      }
    }
  }

  post {
    success {
      script {
        if (env.BRANCH_NAME == 'master') {
          build (job:'../cyberark--secrets-provider-for-k8s/master', wait: false)
        }
      }
    }
    always {
      script {
          env.nightly_msg = ""
          if (params.NIGHTLY) {
            env.nightly_msg = "nightly"
            dir('ee-test'){
                 unstash 'testResultEE'
            }
            archiveArtifacts artifacts: "ee-test/cucumber/*/*.*", fingerprint: false, allowEmptyArchive: true
            archiveArtifacts artifacts: "ee-test/container_logs/*/*", fingerprint: false, allowEmptyArchive: true

            publishHTML([reportDir: 'ee-test/cucumber', reportFiles: 'api/cucumber_results.html, 	authenticators_config/cucumber_results.html, \
                                     authenticators_azure/cucumber_results.html, authenticators_ldap/cucumber_results.html, \
                                     authenticators_oidc/cucumber_results.html, authenticators_status/cucumber_results.html,\
                                     policy/cucumber_results.html , rotators/cucumber_results.html',\
                                     reportName: 'EE Integration reports', reportTitles: '', allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true])

          }
      }
      archiveArtifacts artifacts: "container_logs/*/*", fingerprint: false, allowEmptyArchive: true
      archiveArtifacts artifacts: "coverage/.resultset*.json", fingerprint: false, allowEmptyArchive: true
      archiveArtifacts artifacts: "ci/authn-k8s/output/simplecov-resultset-authnk8s-gke.json", fingerprint: false, allowEmptyArchive: true
      archiveArtifacts artifacts: "cucumber/*/*.*", fingerprint: false, allowEmptyArchive: true

      publishHTML([reportDir: 'cucumber', reportFiles: 'api/cucumber_results.html, 	authenticators_config/cucumber_results.html, \
                               authenticators_azure/cucumber_results.html, authenticators_ldap/cucumber_results.html, \
                               authenticators_oidc/cucumber_results.html, authenticators_status/cucumber_results.html,\
                               policy/cucumber_results.html , rotators/cucumber_results.html',\
                               reportName: 'Integration reports', reportTitles: '', allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true])


      publishHTML([reportDir: 'coverage', reportFiles: 'index.html', reportName: 'Coverage Report', reportTitles: '', allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true])
      junit 'spec/reports/*.xml,spec/reports-audit/*.xml,cucumber/*/features/reports/**/*.xml,ee-test/spec/reports/*.xml,ee-test/spec/reports-audit/*.xml,ee-test/cucumber/*/features/reports/**/*.xml'
      cucumber fileIncludePattern: '**/cucumber_results.json', sortingMethod: 'ALPHABETICAL'


      cleanupAndNotify(currentBuild.currentResult, '#conjur-core', "${env.nightly_msg}", true)
    }
  }
}

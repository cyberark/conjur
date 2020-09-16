#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
    timeout(time: 1, unit: 'HOURS')
  }

  triggers {
    cron(getDailyCronString())
  }

  stages {
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
              TAG = sh(returnStdout: true, script: 'echo $(< VERSION)-$(git rev-parse --short HEAD)')
            }
            scanAndReport("conjur:${TAG}", "HIGH", false)
          }
        }
        stage("Scan Docker image for total issues") {
          steps {
            script {
              TAG = sh(returnStdout: true, script: 'echo $(< VERSION)-$(git rev-parse --short HEAD)')
            }
            scanAndReport("conjur:${TAG}", "NONE", true)
          }
        }
      }
    }

    stage('Prepare For CodeClimate Coverage Report Submission'){
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
          script {
            ccCoverage.dockerPrep()
            sh 'mkdir -p coverage'
            env.CODE_CLIMATE_PREPARED = "true"
          }
        }
      }
    }

    stage('Run Tests') {
      parallel {
        stage('RSpec') {
          steps { sh 'ci/test rspec' }
        }
        stage('Authenticators Config') {
          steps { sh 'ci/test cucumber_authenticators_config' }
        }
        stage('Authenticators Status') {
          steps { sh 'ci/test cucumber_authenticators_status' }
        }
        stage('LDAP Authenticator') {
          steps { sh 'ci/test cucumber_authenticators_ldap' }
        }
        stage('OIDC Authenticator') {
          steps { sh 'ci/test cucumber_authenticators_oidc' }
        }
        stage('Azure Authenticator') {
          steps {
            script {
              node('azure-linux') {
                // get `ci/authn-azure/get_system_assigned_identity.sh` from scm
                checkout scm
                env.AZURE_AUTHN_INSTANCE_IP = sh(script: 'curl icanhazip.com', returnStdout: true).trim()
                env.SYSTEM_ASSIGNED_IDENTITY = sh(script: 'ci/authn-azure/get_system_assigned_identity.sh', returnStdout: true).trim()

                sh('summon -f ci/authn-azure/secrets.yml ci/test cucumber_authenticators_azure')
              }
            }
          }
        }
        // We have 2 stages for GCP Authenticator tests. The first one runs inside
        // a GCE instance and retrieves all the tokens that will be used in the tests.
        // It then stashes the tokens, which are unstashed in the stage that runs the
        // GCP Authenticator tests using the tokens.
        // This way we can have a light-weight GCE instance that has no need for conjurops
        // or git identities and is not open for SSH
 stage('GCP - Stage A - Compute Engine') {
          steps {
            echo '-- Allocating Google Compute Engine'
            script {
              dir('ci/authn-gcp') {
                stash name: 'get_gce_tokens_script', includes: 'get_gce_tokens_to_files.sh'
              }
              node('executor-v2-gcp-small') {
                echo '-- Google Compute Engine allocated'
                echo '-- Get Google Cloud project name from Google metadata server'
                env.GCP_PROJECT = sh (
                  script: 'curl -s -H "Metadata-Flavor: Google" \
                  "http://metadata.google.internal/computeMetadata/v1/project/project-id"',
                  returnStdout: true
                ).trim()
                echo "Google Cloud project name: $GCP_PROJECT"
                unstash 'get_gce_tokens_script'
                sh '''
                ./get_gce_tokens_to_files.sh || exit 1
                '''
                stash name: 'authnGceTokens', includes: 'gce_tokens/*', allowEmpty:false
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
        stage('GCP - Stage B - Google Function') {
          environment {
            GCP_FETCH_TOKEN_FUNCTION = "fetch_token_${BUILD_NUMBER}"
            IDENTITY_TOKEN_FILE = 'identity-token'
            GCP_OWNER_SERVICE_KEY_FILE = "sa-key-file.json"
            GCP_ZONE="us-central1"
          }
          steps {
            echo "Waiting for GCP project name"
            timeout(time: 10, unit: 'MINUTES') {
              waitUntil {
                script {
                  return (env.GCP_PROJECT != null || env.GCP_ENV_ERROR == "true")
                }
              }
            }
            script {
              if (env.GCP_ENV_ERROR == "true") {
                error('GCP_ENV_ERROR cannot deploy function')
              }

              dir('ci/authn-gcp') {
                sh '''
                # Deploy Google Cloud function
                summon ./run_gcloud.sh deploy_function.sh || exit 1
                if [ $? -ne 0 ]; then
                    echo '-- Error deploying Google function'
                    exit 1
                fi
                # Obtain tokens from Google function and write to files
                ./get_func_tokens_to_files.sh
                if [ $? -ne 0 ]; then
                    echo '-- Error obtaining tokens from Google function'
                    exit 1
                fi
                '''
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
        stage('GCP Authenticator - Run tests') {
          steps {
            echo 'Waiting for GCP_TOKENS'
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
                error('GCP_ENV_ERROR cannot run tests check the logs for errors in GCP stages A and B')
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
        stage('Policy') {
          steps { sh 'ci/test cucumber_policy' }
        }
        stage('API') {
          steps { sh 'ci/test cucumber_api' }
        }
        stage('Rotators') {
          steps { sh 'ci/test cucumber_rotators' }
        }
        stage('Kubernetes 1.7 in GKE') {
          steps { sh 'cd ci/authn-k8s && summon ./test.sh gke' }
        }
        stage('Audit') {
          steps { sh 'ci/test rspec_audit'}
        }
      }
    }

    stage('Submit Coverage Report'){
      when {
        expression {
          env.CODE_CLIMATE_PREPARED == "true"
        }
      }
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
      junit 'spec/reports/*.xml,spec/reports-audit/*.xml,cucumber/*/features/reports/**/*.xml'
      cucumber fileIncludePattern: '**/cucumber_results.json', sortingMethod: 'ALPHABETICAL'
      cleanupAndNotify(currentBuild.currentResult, '#conjur-core', '', true)
    }
  }
}

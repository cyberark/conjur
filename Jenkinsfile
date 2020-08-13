#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
    skipDefaultCheckout()  // see 'Checkout SCM' below, once perms are fixed this is no longer needed
    timeout(time: 1, unit: 'HOURS')
  }

  triggers {
    cron(getDailyCronString())
  }

  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
        sh 'git fetch' // to pull the tags
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
        script {
          ccCoverage.dockerPrep()
          sh 'mkdir -p coverage'
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

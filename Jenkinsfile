#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
    skipDefaultCheckout()  // see 'Checkout SCM' below, once perms are fixed this is no longer needed
  }

  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
        sh 'git fetch' // to pull the tags
      }
    }

    stage('Static analysis') {
      parallel {
        stage('brakeman') {
          steps {
            sh 'ci/security-scan -b'
          }
          post {
            always {
              // junit 'brakeman-output.json'
              publishHTML([reportDir: 'brakeman/reports', reportFiles: 'brakeman-output.html', reportName: 'Brakeman Report', reportTitles: '', allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false])
            }
          }
        }
        stage('gem audit') {
          steps {
            sh 'ci/security-scan -a'
          }
        }
        stage('rubocop') {
          steps {
            sh 'ci/docker-rubocop'
            checkstyle pattern: 'reports/xml/checkstyle-result.xml', canComputeNew: false, unstableTotalAll: '0', healthy: '0', failedTotalAll: '20',  unHealthy: '10'
          }
        }
        stage('reek') {
          steps {
            sh 'ci/docker-reek'
            checkstyle pattern: 'reports/reek.xml', canComputeNew: false, unstableTotalAll: '0', healthy: '0', failedTotalAll: '20',  unHealthy: '10'
          }
        }
      }
    }

    stage('Build Docker image') {
      steps {
        sh './build.sh -j'
      }
    }

    stage('Run Tests') {
      parallel {
        stage('RSpec') {
          steps { sh 'cd ci && ./test --rspec' }
        }
        stage('Authenticators') {
          steps { sh 'cd ci && ./test --cucumber-authenticators' }
        }
        stage('Policy') {
          steps { sh 'cd ci && ./test --cucumber-policy' }
        }
        stage('API') {
          steps { sh 'cd ci && ./test --cucumber-api' }
        }
        stage('Rotators') {
          steps { sh 'cd ci && ./test --cucumber-rotators' }
        }
        stage('Kubernetes 1.7 in GKE') {
          steps { sh 'cd ci/authn-k8s && summon ./test.sh gke' }
        }
        /*
        stage('OpenShift 3.3 in AWS') {
          steps { sh 'cd ci/authn-k8s && summon -e openshift33 ./test.sh openshift33' }
        }
        stage('OpenShift 3.7 in AWS') {
          steps { sh 'cd ci/authn-k8s && summon -e openshift37 ./test.sh openshift37' }
        }
        */
      }
      post {
        always {
          junit 'spec/reports/*.xml,cucumber/api/features/reports/**/*.xml,cucumber/policy/features/reports/**/*.xml,cucumber/authenticators/features/reports/**/*.xml'
          publishHTML([reportDir: 'coverage', reportFiles: 'index.html', reportName: 'Coverage Report', reportTitles: '', allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false])
        }
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

    stage('Publish Conjur to Heroku') {
      when {
        branch 'master'
      }
      steps {
        build job: 'release-heroku', parameters: [string(name: 'APP_NAME', value: 'possum-conjur')]
      }
    }
  }

  post {
    always {
      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}

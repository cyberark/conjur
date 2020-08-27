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

    stage('Run Tests OCP 4.3') {
       steps {
        sh 'cd ci/authn-k8s && summon --environment openshift43 ./test.sh openshift43'
       }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: "container_logs/*/*", fingerprint: false, allowEmptyArchive: true
      archiveArtifacts artifacts: "ci/authn-k8s/output/*", fingerprint: false, allowEmptyArchive: true
      archiveArtifacts artifacts: "cucumber/*/*.*", fingerprint: false, allowEmptyArchive: true
      cucumber fileIncludePattern: '**/cucumber_results.json', sortingMethod: 'ALPHABETICAL'
      cleanupAndNotify(currentBuild.currentResult, '#conjur-core', '', true)
    }
  }
}

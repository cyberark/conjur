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

    stage('Security Scans') {
      parallel {
        stage('Static Analysis') {
          steps {
            sh './security-scan.sh -b'
          }
          post {
            always {
              // junit 'brakeman-output.json'
              publishHTML([reportDir: '', reportFiles: 'brakeman-output.html', reportName: 'Brakeman Report', reportTitles: '', allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false])
            }
          }
        }
        stage('Vulnerability Scan') {
          steps {
            sh './security-scan.sh -a'
          }
        }
      }
    }

    stage('Build Docker image') {
      steps {
        sh './build.sh -j'
      }
    }

    stage('Test Docker image') {
      steps {
        sh './test.sh'
      }
      post { always {
        junit 'spec/reports/*.xml,cucumber/api/features/reports/**/*.xml,cucumber/policy/features/reports/**/*.xml'
        publishHTML([reportDir: 'coverage', reportFiles: 'index.html', reportName: 'Coverage Report', reportTitles: '', allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false])
      }}
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

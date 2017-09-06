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

        junit 'spec/reports/*.xml,cucumber/api/features/reports/**/*.xml,cucumber/policy/features/reports/**/*.xml,scaling_features/reports/**/*.xml,reports/*.xml'
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

    stage('Check website for broken links') {
      steps {
        sh './checklinks.sh'
      }
    }

    stage('Publish website - Prod') {
      when {
        branch 'master'
      }
      steps {
        sh 'summon ./website.sh'
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
      sh 'sudo chown -R jenkins:jenkins .'  // bad docker mount creates unreadable files TODO fix this
      deleteDir()  // delete current workspace, for a clean build
    }
    failure {
      slackSend(color: 'danger', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} FAILURE (<${env.BUILD_URL}|Open>)")
    }
    unstable {
      slackSend(color: 'warning', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} UNSTABLE (<${env.BUILD_URL}|Open>)")
    }
  }
}

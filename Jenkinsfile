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
        sh 'sudo chown -R jenkins:jenkins .'  // bad docker mount creates unreadable files TODO fix this
        deleteDir()  // delete current workspace, for a clean build

        checkout scm
      }
    }
    stage('Build Image') {
      steps {
        sh './build.sh'
      }
    }

    stage('Build deb') {
      steps {
        sh './package.sh'

        archiveArtifacts artifacts: '*.deb', fingerprint: true
      }
    }

    stage('Test') {
      steps {
        sh './test.sh'
        
        junit 'spec/reports/*.xml,cucumber/api/features/reports/**/*.xml,cucumber/policy/features/reports/**/*.xml,scaling_features/reports/**/*.xml,reports/*.xml'
      }
    }

    stage('Publish deb'){
      steps {
        sh './publish.sh'
      }
    }

    stage('Push image') {
      steps {
        sh './push-image.sh'
      }
    }

    stage('Publish website') {
      when {
        branch 'master'
      }
      steps {
        sh 'summon ./website.sh'
      }
    }
  }

  post {
    failure {
      slackSend(color: 'danger', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} FAILURE (<${env.BUILD_URL}|Open>)")
    }
    unstable {
      slackSend(color: 'warning', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} UNSTABLE (<${env.BUILD_URL}|Open>)")
    }
  }
}


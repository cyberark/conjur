#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(daysToKeepStr: '14'))
  }

  stages {
    stage('Build Docker image') {
      steps {
        sh './build.sh -j'

        milestone(1)  // Local Docker image is built and tagged
      }
    }

    stage('Test Docker image') {
      steps {
        sh './test.sh'
        junit 'spec/reports/*.xml,cucumber/api/features/reports/**/*.xml,cucumber/policy/features/reports/**/*.xml,scaling_features/reports/**/*.xml,reports/*.xml'
      }
    }

    stage('Push Docker image - internal') {
      steps {
        sh './push-image.sh'
      }
    }

    stage('Push Docker image - external') {
      steps {
        sh './push-image.sh external'  // script checks $BRANCH_NAME

        milestone(2) // Docker image pushed to registries
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

        milestone(3) // Debian package is pushed to Artifactory
      }
    }

    stage('Check website for broken links') {
      steps {
        sh './checklinks.sh'
      }
    }

    stage('Publish website') {
      when {
        branch 'master'
      }
      steps {
        sh 'summon ./website.sh'

        milestone(4)  // conjur.org website is published
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
      sh 'docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd'  // bad docker mount creates unreadable files TODO fix this
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

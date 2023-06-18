#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  triggers {
    cron(getDailyCronString())
  }

  options {
    timestamps()
    buildDiscarder(logRotator(daysToKeepStr: '30'))
  }

  stages {
    stage('Test') {
      parallel {
        stage('Run tests on EE') {
          agent { label 'executor-v2-rhel-ee' }
          steps {
            sh './test.sh'
          }
          post { always {
            stash name: 'eeTestResults', includes: 'spec/reports/*.xml', allowEmpty:true
          }}
        }

        stage('Run tests') {
          steps {
            sh './test.sh'
          }
        }
      }
    }

    stage('Publish to RubyGems') {
      agent { label 'executor-v2' }
      when {
        allOf {
          branch 'master'
          expression {
            boolean publish = false

            try {
              timeout(time: 5, unit: 'MINUTES') {
                input(message: 'Publish to RubyGems?')
                publish = true
              }
            } catch (final ignore) {
              publish = false
            }

            return publish
          }
        }
      }

      steps {
        checkout scm
        sh './publish-rubygem.sh'
        deleteDir()
      }
    }
  }

  post {
    always {
      dir('ee-results'){
        unstash 'eeTestResults'
      }
      junit 'spec/reports/*.xml, ee-results/spec/reports/*.xml'
      cobertura coberturaReportFile: 'spec/coverage/coverage.xml'
      sh 'cp spec/coverage/coverage.xml cobertura.xml'
      ccCoverage("cobertura", "github.com/cyberark/slosilo")

      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}

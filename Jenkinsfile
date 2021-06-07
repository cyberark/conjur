#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
    timeout(time: 2, unit: 'HOURS')
  }

  // "parameterizedCron" is defined by this native Jenkins plugin:
  //     https://plugins.jenkins.io/parameterized-scheduler/
  // "getDailyCronString" is defined by us (URL is wrapped):
  //     https://github.com/conjurinc/jenkins-pipeline-library/blob/master/vars/
  //     getDailyCronString.groovy
  triggers {
    parameterizedCron(getDailyCronString("%NIGHTLY=true"))
  }

  parameters {
    booleanParam(
      name: 'NIGHTLY',
      defaultValue: false,
      description: 'Run tests on all agents and environment including: FIPS'
    )
  }

  stages {
    stage('Fetch tags') {
      steps {
        withCredentials(
          [
            usernameColonPassword(
              credentialsId: 'conjur-jenkins-api', variable: 'GITCREDS'
            )
          ]
        ) {
          sh '''
            git fetch --tags "$(
              git remote get-url origin |
              sed -e "s|https://|https://$GITCREDS@|"
            )"
            # print them out to make sure, can remove when this is robust
            git tag
          '''
        }
      }
    }

    stage('Validate Changelog') {
      steps {
        sh 'ci/parse-changelog'
      }
    }

    stage('Build and test Conjur') {
      when {
        // Run tests only when ANY of the following is true:
        // 1. A non-markdown file has changed.
        // 2. It's running on the master branch (which includes nightly builds).
        // 3. It's a tag-triggered build.
        anyOf {
          // Note: You cannot use "when"'s changeset condition here because it's
          // not powerful enough to express "_only_ md files have changed".
          // Dropping down to a git script was the easiest alternative.
          expression {
            0 == sh(
              returnStatus: true,
              // A non-markdown file has changed.
              script: '''
                git diff  origin/master --name-only |
                grep -v "^.*\\.md$" > /dev/null
              '''
            )
          }

          // Always run the full pipeline on the master branch (which includes
          // nightly builds)
          branch "master"

          // Always run the full pipeline on tags of the form v*
          tag "v*"
        }
      }

      stages {
        stage('Build Docker Image') {
          steps {
            sh './build.sh --jenkins'
          }
        }

        stage('Push images to internal registry') {
          steps {
            // Push images to the internal registry so that they can be used
            // by tests, even if the tests run on a different executor.
            sh './push-image.sh --registry-prefix=registry.tld'
          }
        }

      }

      post {
        success {
          script {
            if (env.BRANCH_NAME == 'master') {
              build(
                job:'../cyberark--secrets-provider-for-k8s/main',
                wait: false
              )
            }
          }
        }

      }
    } // end stage: build and test conjur

    stage('Publish images') {
      parallel {
        stage('On a new tag') {
          when {
            // Only run this stage when it's a tag build matching vA.B.C
            tag(
              pattern: "^v[0-9]+\\.[0-9]+\\.[0-9]+\$",
              comparator: "REGEXP"
            )
          }

          steps {
            sh 'summon -f ./secrets.yml ./push-image.sh'
            // Trigger Conjurops build to push new releases of conjur to ConjurOps Staging
            build(
              job:'../conjurinc--conjurops/master',
              parameters:[
                string(name: 'conjur_oss_source_image', value: "cyberark/conjur:${TAG_NAME}")
              ],
              wait: false
            )
          }
        }

        stage('On a master build') {
          when { branch "master" }
          steps {
            script {
              def tasks = [:]
              tasks["Publish edge to local registry"] = {
                sh './push-image.sh --edge --registry-prefix=registry.tld'
              }
              tasks["Publish edge to DockerHub"] = {
                sh './push-image.sh --edge'
              }
              parallel tasks
            }
          }
        }
      }
    }

    stage('Build Debian and RPM packages') {
      steps {
        sh 'echo "CONJUR_VERSION=5" >> debify.env'
        sh './package.sh'
        archiveArtifacts artifacts: '*.deb', fingerprint: true
        archiveArtifacts artifacts: '*.rpm', fingerprint: true
      }
    }

    stage('Publish Debian and RPM packages'){
      steps {
        sh './publish.sh'
      }
    }
  }

  post {
    always {
      // Explanation of arguments:
      // cleanupAndNotify(buildStatus, slackChannel, additionalMessage, ticket)
      cleanupAndNotify(
        currentBuild.currentResult,
        '#conjur-core',
        "${(params.NIGHTLY ? 'nightly' : '')}",
        true
      )
    }
  }
}

////////////////////////////////////////////
// Functions
////////////////////////////////////////////

// TODO: Do we want to move any of these functions to a separate file?

// Possible minor optimization: Could memoize this. Need to verify it's not
// shared across builds.
def tagWithSHA() {
  sh(
    returnStdout: true,
    script: 'echo $(git rev-parse --short=8 HEAD)'
  )
}



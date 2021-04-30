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

    stage('Snyk') {
      steps {
        snykSecurity(
        severity: 'high', 
        snykInstallation: 'Snyk', 
        snykTokenId: 'snyk-poc-token', 
//        organisation: 'Conjur Team',
        failOnIssues: 'true'//,
//        targetFile: 'Gemfile'
        )
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

        stage('Scan Docker Image') {
          parallel {
            stage("Scan Docker Image for fixable issues") {
              steps {
                scanAndReport("conjur:${tagWithSHA()}", "HIGH", false)
              }
            }
            stage("Scan Docker image for total issues") {
              steps {
                scanAndReport("conjur:${tagWithSHA()}", "NONE", true)
              }
            }
            stage("Scan UBI-based Docker Image for fixable issues") {
              steps {
                scanAndReport("conjur-ubi:${tagWithSHA()}", "HIGH", false)
              }
            }
            stage("Scan UBI-based Docker image for total issues") {
              steps {
                scanAndReport("conjur-ubi:${tagWithSHA()}", "NONE", true)
              }
            }
          }
        }

        // TODO: Add comments explaining which env vars are set here.
        stage('Prepare For CodeClimate Coverage Report Submission') {
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

        // Run outside parallel block to reduce main Jenkins executor load.
        stage('Nightly Only') {
          when {
            expression { params.NIGHTLY }
          }

          stages {
            stage('EE FIPS agent tests') {
              agent { label 'executor-v2-rhel-ee' }

              steps {
                // Catch errors so remaining steps always run.
                catchError {
                  runConjurTests()
                }

                stash(
                  name: 'testResultEE',
                  includes: '''
                    cucumber/*/*.*,
                    container_logs/*/*,
                    spec/reports/*.xml,
                    spec/reports-audit/*.xml,
                    cucumber/*/features/reports/**/*.xml
                  '''
                )
              }

              post {
                always {
                  dir('ee-test'){
                    unstash 'testResultEE'
                  }

                  archiveArtifacts(
                    artifacts: "ee-test/cucumber/*/*.*",
                    fingerprint: false,
                    allowEmptyArchive: true
                  )

                  archiveArtifacts(
                    artifacts: "ee-test/container_logs/*/*",
                    fingerprint: false,
                    allowEmptyArchive: true
                  )

                  publishHTML(
                    reportDir: 'ee-test/cucumber',
                    reportFiles: '''
                      api/cucumber_results.html,
                      authenticators_config/cucumber_results.html,
                      authenticators_azure/cucumber_results.html,
                      authenticators_ldap/cucumber_results.html,
                      authenticators_oidc/cucumber_results.html,
                      authenticators_status/cucumber_results.html
                      policy/cucumber_results.html,
                      rotators/cucumber_results.html
                    ''',
                    reportName: 'EE Integration reports',
                    reportTitles: '',
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true
                  )
                }
              }
            }
          }
        }

        stage('Run environment tests in parallel') {
          parallel {
            stage('Standard agent tests') {
              steps {
                runConjurTests()
              }
            }

            stage('Azure Authenticator') {
              agent { label 'azure-linux' }

              environment {
                // TODO: Move this into the authenticators_azure bash script.
                AZURE_AUTHN_INSTANCE_IP = sh(
                  script: 'curl "http://checkip.amazonaws.com"',
                  returnStdout: true
                ).trim()
                // TODO: Move this into the authenticators_azure bash script.
                SYSTEM_ASSIGNED_IDENTITY = sh(
                  script: 'ci/test_suites/authenticators_azure/' +
                    'get_system_assigned_identity.sh',
                  returnStdout: true
                ).trim()
              }

              steps {
                sh(
                  'summon -f ci/test_suites/authenticators_azure/secrets.yml ' +
                    'ci/test authenticators_azure'
                )
              }

              post {
                always {
                    stash(
                      name: 'testResultAzure',
                      allowEmpty: true,
                      includes: '''
                        cucumber/*azure*/*.*,
                        container_logs/*azure*/*,
                        cucumber_results*.json
                      '''
                    )
                }
              }
            }
            /**
            * GCP Authenticator -- Token Stashing -- Stage 1 of 3
            *
            * In this stage, a GCE instance node is allocated, a script runs
            * and retrieves all the tokens that will be used in authn-gcp
            * tests.  The token are stashed, and later un-stashed and used in
            * the stage that runs the GCP Authenticator tests.  This way we can
            * have a light-weight GCE instance that has no dependency on
            * conjurops or git identities and is not open for SSH.
            */
            stage('GCP Authenticator preparation - Allocate GCE Instance') {
              steps {
                echo '-- Allocating Google Compute Engine'

                script {
                  dir('ci/test_suites/authenticators_gcp') {
                    stash(
                      name: 'get_gce_tokens_script',
                      includes: '''
                        get_gce_tokens_to_files.sh,
                        get_tokens_to_files.sh,
                        tokens_config.json
                      '''
                    )
                  }

                  node('executor-v2-gcp-small') {
                    echo '-- Google Compute Engine allocated'
                    echo '-- Get compute engine instance project name from ' +
                      'Google metadata server.'
                    // TODO: Move this into get_gce_tokens_to_files.sh
                    env.GCP_PROJECT = sh(
                      script: 'curl -s -H "Metadata-Flavor: Google" ' +
                        '"http://metadata.google.internal/computeMetadata/v1/' +
                        'project/project-id"',
                      returnStdout: true
                    ).trim()
                    unstash('get_gce_tokens_script')
                    sh('./get_gce_tokens_to_files.sh')
                    stash(
                      name: 'authnGceTokens',
                      includes: 'gce_token_*',
                      allowEmpty:false
                    )
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

            /**
            * GCP Authenticator -- Allocate Function -- Stage 2 of 3
            *
            * In this stage, Google SDK container executes a script to deploy a
            * function, the function accepts audience in query string and
            * returns a token with that audience.  All the tokens required for
            * testings are obtained and written to function directory, the post
            * stage branch deletes the function.  This stage depends on stage:
            * 'GCP Authenticator preparation - Allocate GCE Instance' to set
            * the GCP project env var.
            */
            stage('GCP Authenticator preparation - Allocate Google Function') {
              environment {
                GCP_FETCH_TOKEN_FUNCTION = "fetch_token_${BUILD_NUMBER}"
                IDENTITY_TOKEN_FILE = 'identity-token'
                GCP_OWNER_SERVICE_KEY_FILE = "sa-key-file.json"
              }
              steps {
                echo "Waiting for GCP project name (Set by stage: " +
                  "'GCP Authenticator preparation - Allocate GCE Instance')"
                timeout(time: 10, unit: 'MINUTES') {
                  waitUntil {
                    script {
                      return (
                        env.GCP_PROJECT != null || env.GCP_ENV_ERROR == "true"
                      )
                    }
                  }
                }
                script {
                  if (env.GCP_ENV_ERROR == "true") {
                    error('GCP_ENV_ERROR cannot deploy function')
                  }

                  dir('ci/test_suites/authenticators_gcp') {
                    sh('summon ./deploy_function_and_get_tokens.sh')
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
                    dir('ci/test_suites/authenticators_gcp') {
                      sh '''
                        # Cleanup Google function
                        summon ./run_gcloud.sh cleanup_function.sh
                      '''
                    }
                  }
                }
              }
            }
            /**
            * GCP Authenticator -- Run Tests -- Stage 3 of 3
            *
            * We have two preparation stages before running the GCP
            * Authenticator tests stage.  This stage waits for GCP preparation
            * stages to complete, un-stashes the tokens created in stage: 'GCP
            * Authenticator preparation - Allocate GCE Instance' and runs the
            * gcp-authn tests.
            */
            stage('GCP Authenticator - Run Tests') {
              steps {
                echo('Waiting for GCP Tokens provisioned by prep stages.')

                timeout(time: 10, unit: 'MINUTES') {
                  waitUntil {
                    script {
                      return (
                        env.GCP_ENV_ERROR == "true" ||
                        (
                          env.GCP_FUNC_TOKENS_FETCHED == "true" &&
                          env.GCE_TOKENS_FETCHED == "true"
                        )
                      )
                    }
                  }
                }
                script {
                  if (env.GCP_ENV_ERROR == "true") {
                    error(
                      'GCP_ENV_ERROR: Check logs for errors in stages 1 and 2'
                    )
                  }
                }
                script {
                  dir('ci/test_suites/authenticators_gcp/tokens') {
                    unstash 'authnGceTokens'
                  }
                  sh 'ci/test authenticators_gcp'
                }
              }
            }
          }
        }
      }
      
      post {
        success {
          script {
            if (env.BRANCH_NAME == 'master') {
              build(
                job:'../cyberark--secrets-provider-for-k8s/master',
                wait: false
              )
            }
          }
        }

        always {
          script {
            unstash 'testResultAzure'

            // Make files available for download.
            archiveFiles('container_logs/*/*')
            archiveFiles('coverage/.resultset*.json')
            archiveFiles(
              'ci/authn-k8s/output/simplecov-resultset-authnk8s-gke.json'
            )
            archiveFiles('cucumber/*/*.*')

            publishHTML([
              reportName: 'Integration reports',
              reportDir: 'cucumber',
              reportFiles: '''
                api/cucumber_results.html,
                authenticators_config/cucumber_results.html,
                authenticators_azure/cucumber_results.html,
                authenticators_ldap/cucumber_results.html,
                authenticators_oidc/cucumber_results.html,
                authenticators_gcp/cucumber_results.html,
                authenticators_status/cucumber_results.html,
                policy/cucumber_results.html,
                rotators/cucumber_results.html
              ''',
              reportTitles: '',
              allowMissing: false,
              alwaysLinkToLastBuild: true,
              keepAll: true
            ])

            publishHTML(
              reportName: 'Coverage Report',
              reportDir: 'coverage',
              reportFiles: 'index.html',
              reportTitles: '',
              allowMissing: false,
              alwaysLinkToLastBuild: true,
              keepAll: true
            )
            junit('''
              spec/reports/*.xml,
              spec/reports-audit/*.xml,
              cucumber/*/features/reports/**/*.xml,
              ee-test/spec/reports/*.xml,
              ee-test/spec/reports-audit/*.xml,
              ee-test/cucumber/*/features/reports/**/*.xml
            '''
            )

            // Make cucumber reports available as html report in Jenkins UI.
            cucumber(
              fileIncludePattern: '**/cucumber_results.json',
              sortingMethod: 'ALPHABETICAL'
            )
          }
        }
      }
    } // end stage: build and test conjur

    stage('Submit Coverage Report') {
      when {
        expression {
          env.CODE_CLIMATE_PREPARED == "true"
        }
      }
      steps{
        sh 'ci/submit-coverage'
      }
    }

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

def archiveFiles(filePattern) {
  archiveArtifacts(
    artifacts: filePattern,
    fingerprint: false,
    allowEmptyArchive: true
  )
}

def runConjurTests() {
  script {
    parallel([
      "RSpec - ${env.STAGE_NAME}": {
        sh 'ci/test rspec'
      },
      "Authenticators Config - ${env.STAGE_NAME}": {
        sh 'ci/test authenticators_config'
      },
      "Authenticators Status - ${env.STAGE_NAME}": {
        sh 'ci/test authenticators_status'
      },
      "LDAP Authenticator - ${env.STAGE_NAME}": {
        sh 'ci/test authenticators_ldap'
      },
      "OIDC Authenticator - ${env.STAGE_NAME}": {
        sh 'ci/test authenticators_oidc'
      },
      "Policy - ${env.STAGE_NAME}": {
        sh 'ci/test policy'
      },
      "API - ${env.STAGE_NAME}": {
        sh 'ci/test api'
      },
      "Rotators - ${env.STAGE_NAME}": {
        sh 'ci/test rotators'
      },
      "Kubernetes 1.7 in GKE - ${env.STAGE_NAME}": {
        sh 'cd ci/authn-k8s && summon ./test.sh gke'
      },
      "Audit - ${env.STAGE_NAME}": {
        sh 'ci/test rspec_audit'
      },
      "Policy Parser - ${env.STAGE_NAME}": {
        sh 'cd gems/policy-parser && ./test.sh'
      }
    ])
  }
}

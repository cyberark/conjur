#!/usr/bin/env groovy

/*
NOTE TO DEVELOPERS:

When developing, you'll often need to use the CI to test to verify work, but
only care about the result of a single test, or a few tests.  In this case, you
can dramatically cut down your cycle time (to about 10 minutes) by running only
the relevant tests.

There are two ways to do this:

1. (most common) Temporarily edit the Jenkinsfile.  You'll need to undo your
   change when your PR is ready for review.  Simply edit the default value of
   the 'RUN_ONLY' parameter (defined in the parameters block below) to a
   space-separated list consisting of test names from the list below.

2. Re-run the same code (perhaps because of a flaky test) directly in Jenkins.
   In this case, go to your branch in Jenkins (not Blue Ocean). For example:

   https://jenkins.conjur.net/job/cyberark--conjur/job/<MY-NICE_BRANCH>

   And click on "Build with Parameters" in the left nav.  In the RUN_ONLY text
   input, enter a list of space-separated test names that you want to run, from
   the list below:

LIST OF ALL TEST NAMES

These are defined in runConjurTests, and also include the one-offs
"azure_authenticator" and "gcp_authenticator":

    rspec
    authenticators_config
    authenticators_status
    authenticators_ldap
    authenticators_oidc
    authenticators_jwt
    policy
    api
    rotators
    authenticators_k8s
    rspec_audit
    policy_parser
    azure_authenticator
    gcp_authenticator
*/

// Automated release, promotion and dependencies
properties([
  // Include the automated release parameters for the build
  release.addParams(),
  // Dependencies of the project that should trigger builds
  dependencies(['cyberark/conjur-base-image',
                'cyberark/conjur-api-ruby',
                'conjurinc/debify'])
])

// Performs release promotion.  No other stages will be run
if (params.MODE == "PROMOTE") {
  release.promote(params.VERSION_TO_PROMOTE) { sourceVersion, targetVersion, assetDirectory ->
    sh "docker pull registry.tld/conjur:${sourceVersion}"
    sh "docker pull registry.tld/conjur-ubi:${sourceVersion}"
    sh "summon -f ./secrets.yml ./publish-images.sh --promote --redhat --base-version=${sourceVersion} --version=${targetVersion}"

    // Trigger Conjurops build to push newly promoted releases of conjur to ConjurOps Staging
    build(
      job:'../conjurinc--conjurops/master',
      parameters:[
        string(name: 'conjur_oss_source_image', value: "cyberark/conjur:${targetVersion}")
      ],
      wait: false
    )
  }
  return
}

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
    string(
      name: 'RUN_ONLY',
      description:
        'Run only one (or a few) test for development. Space-separated list, ' +
        'empty to run all tests. See Jenkinsfile for details.',
      // See note at top of file for temporarily changing this value during
      // development.
      defaultValue: ''
    )
    string(
      name: 'CUCUMBER_FILTER_TAGS',
      description: 'Filter which cucumber tags will run (e.g. "not @performance")',
      defaultValue: defaultCucumberFilterTags(env)
    )

  }

  environment {
    // Sets the MODE to the specified or autocalculated value as appropriate
    MODE = release.canonicalizeMode()
  }

  stages {
    // Aborts any builds triggered by another project that wouldn't include any changes
    stage ("Skip build if triggering job didn't create a release") {
      when {
        expression {
          MODE == "SKIP"
        }
      }
      steps {
        script {
          currentBuild.result = 'ABORTED'
          error("Aborting build because this build was triggered from upstream, but no release was built")
        }
      }
    }
    // Generates a VERSION file based on the current build number and latest version in CHANGELOG.md
    stage('Validate Changelog and set version') {
      steps {
        updateVersion("CHANGELOG.md", "${BUILD_NUMBER}")
        stash name: 'version_info', includes: 'VERSION'
      }
    }

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
      when {
        expression { params.RUN_ONLY == '' }
      }
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
            sh './publish-images.sh --internal'
          }
        }

        stage('Scan Docker Image') {
          when {
            expression { params.RUN_ONLY == '' }
          }
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
          when {
            expression { params.RUN_ONLY == '' }
          }
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

          environment {
            CUCUMBER_FILTER_TAGS = "${params.CUCUMBER_FILTER_TAGS}"
          }

          stages {
            stage('EE FIPS agent tests') {
              agent { label 'executor-v2-rhel-ee' }

              steps {
                unstash 'version_info'
                // Catch errors so remaining steps always run.
                catchError {
                  runConjurTests(params.RUN_ONLY)
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
                      authenticators_jwt/cucumber_results.html,
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
              environment {
                CUCUMBER_FILTER_TAGS = "${params.CUCUMBER_FILTER_TAGS}"
              }

              steps {
                runConjurTests(params.RUN_ONLY)
              }
            }

            stage('Azure Authenticator') {
              when {
                expression {
                  testShouldRun(params.RUN_ONLY, "azure_authenticator")
                }
              }

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
                unstash 'version_info'
                // Grant access to this Jenkins agent's IP to AWS security groups
                // This is required for access to the internal docker registry
                // from outside EC2.
                grantIPAccess()
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
                    // Remove this Agent's IP from IPManager's prefix list
                    // There are a limited number of entries, so it remove it
                    // rather than waiting for it to expire.
                    removeIPAccess()
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
              when {
                expression {
                  testShouldRun(params.RUN_ONLY, "gcp_authenticator")
                }
              }
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
              when {
                expression {
                  testShouldRun(params.RUN_ONLY, "gcp_authenticator")
                }
              }
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
              when {
                expression {
                  testShouldRun(params.RUN_ONLY, "gcp_authenticator")
                }
              }
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
                job:'../cyberark--secrets-provider-for-k8s/main',
                wait: false
              )
            }
          }
        }

        always {
          script {

            // Only unstash azure if it ran.
            if (testShouldRun(params.RUN_ONLY, "azure_authenticator")) {
              unstash 'testResultAzure'
            }

            // Make files available for download.
            archiveFiles('container_logs/*/*')
            archiveFiles('coverage/.resultset*.json')
            archiveFiles('coverage/coverage.json')
            archiveFiles('coverage/codeclimate.json')
            archiveFiles(
              'ci/test_suites/authenticators_k8s/output/simplecov-resultset-authnk8s-gke.json'
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
                authenticators_jwt/cucumber_results.html,
                authenticators_gcp/cucumber_results.html,
                authenticators_status/cucumber_results.html,
                authenticators_k8s/cucumber_results.html,
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

    stage("Release Conjur images and packages") {
      when {
        expression {
          MODE == "RELEASE"
        }
      }
      steps {
        release { billOfMaterialsDirectory, assetDirectory ->
          // Publish docker images
          sh './publish-images.sh --edge --dockerhub'

          // Create deb and rpm packages
          sh 'echo "CONJUR_VERSION=5" >> debify.env'
          sh './package.sh'
          archiveArtifacts artifacts: '*.deb', fingerprint: true
          archiveArtifacts artifacts: '*.rpm', fingerprint: true
          sh "cp *.rpm ${assetDirectory}/."
          sh "cp *.deb ${assetDirectory}/."

          // Publish deb and rpm packages
          sh './publish.sh'
        }
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

def testShouldRun(run_only_str, test) {
  return run_only_str == '' || run_only_str.split().contains(test)
}

// "run_only_str" is a space-separated string specifying the subset of tests to
// run.  If it's empty, all tests are run.
def runConjurTests(run_only_str) {

  all_tests = [
    "rspec": [
      "RSpec - ${env.STAGE_NAME}": { sh 'ci/test rspec' }
    ],
    "authenticators_config": [
      "Authenticators Config - ${env.STAGE_NAME}": {
        sh 'ci/test authenticators_config'
      }
    ],
    "authenticators_status": [
      "Authenticators Status - ${env.STAGE_NAME}": {
        sh 'ci/test authenticators_status'
      }
    ],
    "authenticators_k8s": [
      "K8s Authenticator - ${env.STAGE_NAME}": {
        sh 'ci/test authenticators_k8s'
      }
    ],
    "authenticators_ldap": [
      "LDAP Authenticator - ${env.STAGE_NAME}": {
        sh 'ci/test authenticators_ldap'
      }
    ],
    "authenticators_oidc": [
      "OIDC Authenticator - ${env.STAGE_NAME}": {
        sh 'ci/test authenticators_oidc'
      }
    ],
    "authenticators_jwt": [
      "JWT Authenticator - ${env.STAGE_NAME}": {
        sh 'ci/test authenticators_jwt'
      }
    ],
    "policy": [
      "Policy - ${env.STAGE_NAME}": {
        sh 'ci/test policy'
      }
    ],
    "api": [
      "API - ${env.STAGE_NAME}": {
        sh 'ci/test api'
      }
    ],
    "rotators": [
      "Rotators - ${env.STAGE_NAME}": {
        sh 'ci/test rotators'
      }
    ],
    "rspec_audit": [
      "Audit - ${env.STAGE_NAME}": {
        sh 'ci/test rspec_audit'
      }
    ],
    "policy_parser": [
      "Policy Parser - ${env.STAGE_NAME}": {
        sh 'cd gems/policy-parser && ./test.sh'
      }
    ]
  ]

  // Filter for the tests we want run, if requested.
  parallel_tests = all_tests
  tests = run_only_str.split()

  if (tests.size() > 0) {
    parallel_tests = all_tests.subMap(tests)
  }

  // Create the parallel pipeline.
  //
  // Since + merges two maps together, sum() combines the individual values of
  // parallel_tests into one giant map whose keys are the stage names and
  // whose values are the blocks to be run.
  script {
    parallel(
      parallel_tests.values().sum()
    )
  }
}

def defaultCucumberFilterTags(env) {
  if(env.BRANCH_NAME == 'master' || env.TAG_NAME?.trim()) {
    // If this is a master or tag build, we want to run all of the tests. So
    // we use an empty filter string.
    return ''
  }

  // For all other branch builds, only run the @smoke tests by default
  return '@smoke'
}

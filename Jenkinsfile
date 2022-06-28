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
    sh "docker pull registry.tld/cyberark/conjur:${sourceVersion}"
    sh "docker tag registry.tld/cyberark/conjur:${sourceVersion} conjur:${sourceVersion}"
    sh "docker pull registry.tld/conjur-ubi:${sourceVersion}"
    sh "docker tag registry.tld/conjur-ubi:${sourceVersion} conjur-ubi:${sourceVersion}"
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
    stage('Build and publish internal appliance') {
      steps{
        sh './build-and-publish-internal-appliance.sh'
      }
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

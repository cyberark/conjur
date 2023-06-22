require 'pact/provider/rspec'
require_relative '../services_consumers/pact_conjur_api_java.rb'
require 'spec_helper'
provider_version = ENV['GIT_COMMIT'] || `git rev-parse --verify HEAD`.strip
provider_branch = ENV['GIT_BRANCH'] || `git name-rev --name-only HEAD`.strip
publish_flag = ENV['PUBLISH_VERIFICATION_RESULTS'] == 'true' # or some way of detecting you're running on CI like ENV['CI'] == 'true'




Pact.service_provider "Conjur Cloud" do
  app_version provider_version
  app_version_branch provider_branch
  publish_verification_results publish_flag
  # honours_pact_with 'conjur-app' do
  honours_pacts_from_pact_broker do

    # This example points to a local file, however, on a real project with a continuous
    # integration box, you would use a [Pact Broker](https://github.com/pact-foundation/pact_broker) or publish your pacts as artifacts,
    # and point the pact_uri to the pact published by the last successful build.

    pact_broker_base_url 'https://cyberark2.pactflow.io' , { token: '_e68R-wKTXNqyJ2KCUDy5A' }
    verbose true
    enable_pending true

  end

end
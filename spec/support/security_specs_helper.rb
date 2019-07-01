# frozen_string_literal: true

require 'spec_helper'

shared_context "security mocks" do
  let (:test_account) { 'test-account' }
  let (:non_existing_account) { 'non-existing' }
  let (:fake_authenticator_name) { 'authn-x' }
  let (:test_user_id) { 'some-user' }
  let (:two_authenticator_env) { "#{fake_authenticator_name}/service1, #{fake_authenticator_name}/service2" }

  def mock_webservice(resource_id)
    double('webservice').tap do |webservice|
      allow(webservice).to receive(:authenticator_name)
                             .and_return("some-string")

      allow(webservice).to receive(:name)
                             .and_return("some-string")

      allow(webservice).to receive(:resource_id)
                             .and_return(resource_id)
    end
  end

end

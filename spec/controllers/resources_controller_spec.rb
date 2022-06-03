# frozen_string_literal: true

require 'spec_helper'
require 'parallel'

DatabaseCleaner.strategy = :truncation

describe ResourcesController, type: :request do
  #before(:all) do
    #Slosilo["authn:rspec"] ||= Slosilo::Key.new
  #end

  before do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new

    allow_any_instance_of(described_class).to(
      receive_messages(current_user: current_user)
    )
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  # :reek:UtilityFunction is okay for this test util
  def variable(name)
    Resource["rspec:variable:#{name}"]
  end

  describe '#post' do

    let(:resources_url) do
      '/resources/rspec/index'
    end
    # TODO: Avoid duplication between here and "spec/support/authentication.rb"
    # This will require nontrivial refactoring and may be better waiting for a
    # larger overhaul of the test code.
    let(:token_auth_header) do
      bearer_token = Slosilo["authn:rspec"].signed_token(current_user.login)
      token_auth_str =
        "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
      { 'HTTP_AUTHORIZATION' => token_auth_str }
    end
    def headers_with_auth()
      token_auth_header()
    end

    def list_resources_without_limit()
      get(resources_url, env: headers_with_auth())
    end

    def list_resources_with_limit(limit)
      get(resources_url, env: headers_with_auth(), params: {:limit => limit})
    end

    it "list resources without limit and without config" do
      Rails.application.config.conjur_config.max_resources_limit = 0
      list_resources_without_limit()
      expect(response.code).to eq("200")
    end

    it "list resources with limit and without config" do
      Rails.application.config.conjur_config.max_resources_limit = 0
      list_resources_with_limit(50)
      expect(response.code).to eq("200")
    end

    it "list resources without limit and with config" do
      Rails.application.config.conjur_config.max_resources_limit = 100
      list_resources_without_limit()
      expect(response.code).to eq("200")
    end

    it "list resources with limit 50 and with config" do
      Rails.application.config.conjur_config.max_resources_limit = 100
      list_resources_with_limit(50)
      expect(response.code).to eq("200")
    end

    it "list resources with limit 500 and with config" do
      Rails.application.config.conjur_config.max_resources_limit = 100
      list_resources_with_limit(500)
      expect(response.code).to eq("422")
    end

end
end

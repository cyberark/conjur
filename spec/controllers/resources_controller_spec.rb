# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation

describe ResourcesController, type: :request do

  before do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  describe '#post' do

    before(:each) do
      Rails.application.config.conjur_config.api_resource_list_limit_max = 0
      load_variables()
    end

    let(:resources_url) do
      '/resources/rspec'
    end

    let(:policies_url) do
      '/policies/rspec/policy/root'
    end

    let(:token_auth_header) do
      bearer_token = Slosilo["authn:rspec"].signed_token(current_user.login)
      token_auth_str =
        "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
      { 'HTTP_AUTHORIZATION' => token_auth_str }
    end

    def list_resources_without_limit()
      get(resources_url, env: token_auth_header())
    end

    def list_resources_with_limit(limit)
      get(resources_url, env: token_auth_header(), params: {:limit => limit})
    end

    def count_resources_without_limit()
      get(resources_url, env: token_auth_header(), params: {:count => "true"})
    end

    def count_resources_with_limit(limit)
      get(resources_url, env: token_auth_header(), params: {:limit => limit, :count => "true"})
    end

    def load_variables()
      payload = '[!variable preexisting\n!variable preexisting1]'
      put(policies_url, env: token_auth_header.merge({ 'RAW_POST_DATA' => payload }))
    end

    context 'with default configuration' do
      it "should list all resources when limit not defined" do
        list_resources_without_limit()
        expect(response.code).to eq("200")
        expect(JSON.parse(response.body).size).to eq(2)
      end

      it "should list resources according to query param limit when limit defined" do
        list_resources_with_limit(1)
        expect(response.code).to eq("200")
        expect(JSON.parse(response.body).size).to eq(1)
      end
    end

    context 'with custom configuration' do
      it "should list resources according to custom configuration when limit not defined" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 1
        list_resources_without_limit()
        expect(response.code).to eq("200")
        expect(JSON.parse(response.body).size).to eq(1)
      end

      it "should list resources according to query param limit when custom configuration exceeds limit" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 2
        list_resources_with_limit(1)
        expect(response.code).to eq("200")
        expect(JSON.parse(response.body).size).to eq(1)
      end

      it "should throw error when limit exceeds custom configuration" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 1
        list_resources_with_limit(2)
        expect(response.code).to eq("422")
      end
    end

    context 'when validating count request' do
      it "should count all resources when custom configuration defined" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 1
        count_resources_without_limit()
        expect(response.code).to eq("200")
        expect(response.body).to eq("{\"count\":2}")
      end

      it "should count all resources when custom configuration not defined" do
        count_resources_without_limit()
        expect(response.code).to eq("200")
        expect(response.body).to eq("{\"count\":2}")
      end

      # There is a currently a bug in the API when supplying both the `limit`
      # and `count` parameters. A count response shouldn't be affected by
      # the `limit` parameter. This should be changed when the bug is fixed (ONYX-22079)
      it "should count resources according to query param limit " do
        count_resources_with_limit(1)
        expect(response.body).to eq("{\"count\":1}")
      end
    end
  end
end

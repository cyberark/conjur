# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation

describe ResourcesController, type: :request do

  before do
    init_slosilo_keys("rspec")
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:alice_user) { Role.find_or_create(role_id: 'rspec:user:alice') }

  describe "resource permissions" do
    let(:test_policy) do
      <<~POLICY
        - !user alice
        - !variable perm_secret
        - !permit
          resource: !variable perm_secret
          privilege: [ update ]
          role: !user alice
      POLICY
    end
    before do
      # Load the test policy into Conjur
      put(
        '/policies/rspec/policy/root',
        env: token_auth_header(role: current_user).merge(
          { 'RAW_POST_DATA' => test_policy }
        )
      )
      assert_response :success
    end
    context 'when validating check permission request' do
      it "should return true when permission exists" do
        get(
          "/resources/rspec/variable/perm_secret?check=true&role=alice&privilege=update",
          env: token_auth_header(role: current_user)
        )
        expect(response.code).to eq("200")
        expect(response.body).to eq("{\"count\":12}")
      end
    end
  end

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

    def list_resources(limit: nil, offset: nil, count: false, short: false, kind: false)
      params = {}
      params.merge!({ :limit => limit }) if limit
      params.merge!({ :offset => offset }) if offset
      params.merge!({ :count => count }) if count
      params.merge!({ :short => short }) if short
      params.merge!({ :kind => kind }) if kind
      get(
        resources_url,
        env: token_auth_header(role: current_user),
        params: params
      )
    end

    def count_resources(limit: nil)
      list_resources(limit: limit, count: true)
    end

    def load_variables()
      payload = '[!variable a, !variable b, !variable c, !variable d, !host a, !host b, !host c, !host d, !layer a, !layer b, !layer c]'
      put(
        policies_url,
        env: token_auth_header(role: current_user).merge({ 'RAW_POST_DATA' => payload })
      )
    end

    def load_many_variables(num_of_variables)
      payload = "[!host a, ".dup
      (1..num_of_variables).each { |i|
        payload += "!variable a#{i}, "
      }
      payload[-1] = "]"

      put(
        policies_url,
        env: token_auth_header(role: current_user).merge({ 'RAW_POST_DATA' => payload })
      )
    end

    context 'with default configuration' do
      context 'with short param defined' do
        it 'should return only resources' do
          list_resources(short: true)
          @resources = JSON.parse(response.body)
          expect(@resources.size).to eq(12)
          # For short result validate that each resource is a simple string = the resource id
          expect(@resources[0].is_a?(String))
          expect(@resources[0]).to eq("rspec:host:a")
        end
      end
      context 'with no query params defined' do
        before(:each) do
          list_resources()
          @resources = JSON.parse(response.body)
        end

        it 'should return a 200 status code' do
          expect(response.code).to eq("200")
        end

        it 'should list all resources' do
          expect(@resources.size).to eq(12)
          # For full result validate that each resource is a complex object
          expect not(@resources[0].is_a?(String))
          expect(@resources[0]['id']).to eq("rspec:host:a")
        end

        it 'should order resources alphabetically by resource id' do
          @resources.each_with_index do |resource, idx|
            next if idx == 0
            expect(resource["id"]).to be > @resources[idx-1]["id"]
          end
        end
      end
      context 'with limit query param defined' do
        before(:each) do
          list_resources(limit: 5)
          @resources = JSON.parse(response.body)
        end

        it 'should return a 200 status code' do
          expect(response.code).to eq("200")
        end

        it 'should list resources according to the provided limit' do
          expect(@resources.size).to eq(5)
        end

        it 'should order resources alphabetically by resource id' do
          @resources.each_with_index do |resource, idx|
            next if idx == 0
            expect(resource["id"]).to be > @resources[idx-1]["id"]
          end
        end
      end
      context 'with offset query param defined' do
        before(:each) do
          list_resources(offset: 1)
          @resources = JSON.parse(response.body)
        end

        it 'should return a 200 status code' do
          expect(response.code).to eq("200")
        end

        it 'should offset resources according to the provided offset' do
          list_resources()
          all_resources = JSON.parse(response.body)

          expect(@resources[0]).to eq(all_resources[1])
        end

        it 'should limit list to 10 resources when offset defined and limit not defined' do
          expect(@resources.size).to eq(10)
        end

        it 'should order resources alphabetically by resource id' do
          @resources.each_with_index do |resource, idx|
            next if idx == 0
            expect(resource["id"]).to be > @resources[idx-1]["id"]
          end
        end
      end
      context 'with max limit query param defined' do
        before(:each) do
          load_many_variables(1001)
          list_resources(limit: 1000, kind: "variable")
          @resources = JSON.parse(response.body)
        end

        it 'should return a 200 status code' do
          expect(response.code).to eq("200")
        end

        it 'should list resources according to the provided limit' do
          expect(@resources.size).to eq(1000)
        end
      end
    end

    context 'with custom configuration' do
      it "should list resources according to custom configuration when limit not defined" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 1
        list_resources()
        expect(response.code).to eq("200")
        expect(JSON.parse(response.body).size).to eq(1)
      end

      it "should list resources according to query param limit when custom configuration exceeds limit" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 2
        list_resources(limit: 1)
        expect(response.code).to eq("200")
        expect(JSON.parse(response.body).size).to eq(1)
      end

      it "should throw error when limit exceeds custom configuration" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 1
        list_resources(limit: 2)
        expect(response.code).to eq("422")
      end
    end

    context 'when validating count request' do
      it "should count all resources when custom configuration defined" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 1
        count_resources()
        expect(response.code).to eq("200")
        expect(response.body).to eq("{\"count\":12}")
      end

      it "should count all resources when custom configuration not defined" do
        count_resources()
        expect(response.code).to eq("200")
        expect(response.body).to eq("{\"count\":12}")
      end

      # There is a currently a bug in the API when supplying both the `limit`
      # and `count` parameters. A count response shouldn't be affected by
      # the `limit` parameter. This should be changed when the bug is fixed (ONYX-22079)
      it "should count resources according to query param limit " do
        count_resources(limit: 1)
        expect(response.body).to eq("{\"count\":1}")
      end
    end
  end
end

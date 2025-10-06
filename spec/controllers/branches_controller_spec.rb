# frozen_string_literal: true

require 'spec_helper'
require 'spec_helper_policy'

DatabaseCleaner.allow_remote_database_url = true
DatabaseCleaner.strategy = :truncation

describe(BranchesController, type: :request) do
  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:init_data) do
    <<~POLICY
      - !user alice
      - !user bob
      - !policy data
    POLICY
  end

  before do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new

    post(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(RAW_POST_DATA: init_data)
    )
    assert_response :success

    load Rails.root.join('config/routes.rb')
  end

  def headers_with_auth(payload = nil)
    headers = { 'Accept' => V2RestController::API_V2_HEADER }
    headers.merge!({ 'RAW_POST_DATA' => payload }, 'Content-Type' => 'application/json') if payload
    token_auth_header(role: admin_user).merge(headers)
  end

  let(:branches_url) { '/branches/rspec' }
  let(:branch_name) { 'test-branch' }

  let(:branch_params) do
    { name: branch_name,
      branch: 'root',
      owner: { kind: 'user', id: 'alice' },
      annotations: { ann: 'ann-val' } }
  end

  let(:resp_branch) { branch_params.merge(branch: '/') }

  def post_payload(payload)
    post(branches_url, env: headers_with_auth(payload))
  end

  def read_one
    get("#{branches_url}/#{branch_name}", env: headers_with_auth)
  end

  def read_list
    get(branches_url, env: headers_with_auth)
  end

  def patch_payload(payload)
    patch("#{branches_url}/#{branch_name}", env: headers_with_auth(payload))
  end

  def delete_one
    delete("#{branches_url}/#{branch_name}", env: headers_with_auth)
  end

  def expect_resp_body(expected_hash)
    expect(JSON.parse(response.body).deep_symbolize_keys).to match(expected_hash.deep_symbolize_keys)
  end

  describe "#create" do
    it "creates a branch successfully" do
      post_payload(branch_params.to_json)
      assert_response :success
      expect_resp_body(resp_branch)
    end

    it "fails to create a branch with no name" do
      post_payload({ branch: 'invalid-branch' }.to_json)
      assert_response :unprocessable_entity
      expect(JSON.parse(response.body)).to eq("code" => "422", "message" => "CONJ00190W Missing required parameter: name")
    end

    it "fails to create a branch with empty name" do
      post_payload({ name: '', branch: 'invalid-branch' }.to_json)
      assert_response :unprocessable_entity
      expect(JSON.parse(response.body)).to eq("code" => "422", "message" => "CONJ00190W Missing required parameter: ")
    end

    it "fails to create a branch with invalid owner" do
      post_payload({ name: 'invalid<branch', branch: 'root', owner: { kind: 'invalid', id: 'alice' } }.to_json)
      assert_response :unprocessable_entity
      expect(JSON.parse(response.body)).to eq("code"=>"422", "message"=>"Kind 'invalid' is not a valid owner kind")
    end

    it "fails to create a branch with invalid annotation" do
      post_payload({ name: 'invalid-branch', branch: 'root', owner: { kind: 'user', id: 'alice' }, annotations: { '<>': 'value' } }.to_json)
      assert_response :unprocessable_entity
      expect(JSON.parse(response.body)).to eq("code" => "422", "message" =>"<> annotation key format error '<>'")
    end
  end

  describe "#read_one" do
    it "read a branch successfully" do
      post_payload(branch_params.to_json)
      read_one
      assert_response :success
      expect_resp_body(resp_branch)
    end

    it "fails to read a non-existing branch" do
      read_one
      assert_response :not_found
      expect(JSON.parse(response.body)).to eq("code" => "404", "message" => "Branch 'test-branch' not found in account 'rspec'")
    end
  end

  describe "#read_list" do
    it "read branches successfully" do
      post_payload(branch_params.to_json)
      post_payload(branch_params.merge(name: 'test-branch-1').to_json)
      read_list
      assert_response :success
      expect_resp_body({
        branches: [
          { name: "data", branch: "/", owner: { id: "admin", kind: "user" }, annotations: {} },
          resp_branch,
          resp_branch.merge(name: 'test-branch-1')
        ],
        count: 3
      })
    end

    it "fails to read branches with invalid account" do
      get("#{branches_url}?limit=-3", env: headers_with_auth)
      assert_response :unprocessable_entity
      expect(JSON.parse(response.body)).to eq("code" => "422", "message" => "Limit must be greater than or equal to 0")
    end
  end

  describe "#update_partially" do
    it "update a branch successfully" do
      post_payload(branch_params.to_json)
      patch_payload({ owner: { kind: 'user', id: 'bob' } }.to_json)
      assert_response :success
    end

    it "fails to update a branch with invalid owner" do
      post_payload(branch_params.to_json)
      patch_payload({ owner: { kind: 'invalid', id: 'alice' } }.to_json)
      assert_response :unprocessable_entity
      expect(JSON.parse(response.body)).to eq("code" => "422", "message" => "Kind 'invalid' is not a valid owner kind")
    end
  end

  describe "#delete" do
    it "delete a branch successfully" do
      post_payload(branch_params.to_json)
      read_one
      assert_response :success
      delete_one
      assert_response :success
      read_one
      assert_response :not_found
    end

    it "delete a branch that is own owner successfully" do
      post_payload(branch_params.to_json)
      patch_payload({ owner: { id: branch_name, kind: 'policy' } }.to_json)
      assert_response :success
      apply_policy(
        policy: <<~YAML
          - !permit
            role: !user admin
            privilege: [ read, update, delete ]
            resource: !policy 'test-branch'
        YAML
      )
      read_one
      assert_response :success
      delete_one
      assert_response :success
      read_one
      assert_response :not_found
    end

    it "fails to delete not existing branch" do
      delete_one
      assert_response :not_found
      expect(JSON.parse(response.body)).to eq("code" => "404", "message" => "Branch 'test-branch' not found in account 'rspec'")
    end
  end
end

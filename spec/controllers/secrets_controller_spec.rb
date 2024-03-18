# frozen_string_literal: true

require 'spec_helper'

describe SecretsController, type: :request do

  let(:account) { "rspec" }
  let(:user_owner_id) { 'rspec:user:admin' }
  let(:host_id) { 'rspec:host:hosty' }
  let(:admin_user) { Role.find_or_create(role_id: user_owner_id) }
  let(:my_host) { Role.find_or_create(role_id: host_id) }

  context 'pCloud secrets fetch monitoring' do
    let(:pcloud_var_id) { "#{account}:variable:data/vault/pcloud_secret" }
    let(:non_pcloud_var_id) { "#{account}:variable:data/conjur_secret" }
    let(:access_variable_id) { "#{account}:variable:internal/telemetry/first_pcloud_fetch" }
    before do
      init_slosilo_keys("rspec")
      Role.find_or_create(role_id: user_owner_id)
      Resource.create(resource_id: pcloud_var_id, owner_id: user_owner_id)
      Secret.create(resource_id: pcloud_var_id, value: 'secret')
      Resource.create(resource_id: non_pcloud_var_id, owner_id: user_owner_id)
      Secret.create(resource_id: non_pcloud_var_id, value: 'secret')
      Resource.create(resource_id: access_variable_id, owner_id: user_owner_id)
      described_class.set_pcloud_access(nil)
    end

    it 'pCloud fetch is checked only until relevant calls' do
      # fetch show with user
      checked_access = false
      allow_any_instance_of(described_class).to receive(:check_first_pcloud_fetch).and_wrap_original do |original_method, *args, &block|
        checked_access = true
        original_method.call(*args, &block)
      end
      get("/secrets/#{pcloud_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))
      expect(checked_access).to be_truthy
      checked_access = false
      # fetch show for non pCloud secret
      get("/secrets/#{non_pcloud_var_id.gsub(':', '/')}", env: token_auth_header(role: my_host))
      expect(checked_access).to be_truthy
      checked_access = false
      # fetch batch with user
      get("/secrets?variable_ids=#{pcloud_var_id}", env: token_auth_header(role: admin_user))
      expect(checked_access).to be_truthy
      checked_access = false
      # fetch batch for non pCloud secret
      get("/secrets?variable_ids=#{non_pcloud_var_id}", env: token_auth_header(role: my_host))
      expect(checked_access).to be_truthy
      checked_access = false

      # fetch show with host and pCloud secret
      get("/secrets/#{pcloud_var_id.gsub(':', '/')}", env: token_auth_header(role: my_host))
      expect(checked_access).to be_truthy
      checked_access = false

      # Subsequent calls don't check fetch
      get("/secrets/#{pcloud_var_id.gsub(':', '/')}", env: token_auth_header(role: my_host))
      expect(checked_access).to be_falsey
      get("/secrets?variable_ids=#{pcloud_var_id}", env: token_auth_header(role: my_host))
      expect(checked_access).to be_falsey
      get("/secrets?variable_ids=#{non_pcloud_var_id}", env: token_auth_header(role: my_host))
      expect(checked_access).to be_falsey
      get("/secrets?variable_ids=#{non_pcloud_var_id}", env: token_auth_header(role: admin_user))
      expect(checked_access).to be_falsey
    end
  end

  context "Secret are saved to Redis when appropriate" do
    let(:data_var_id) { "#{account}:variable:data/conjur_secret" }
    let(:internal_secret) { "#{account}:variable:internal/secret" }
    let(:payload) { {'RAW_POST_DATA' => 'new-secret'} }

    before do
      init_slosilo_keys("rspec")
      Role.find_or_create(role_id: user_owner_id)
      Resource.create(resource_id: data_var_id, owner_id: user_owner_id)
      Secret.create(resource_id: data_var_id, value: 'secret')
      Resource.create(resource_id: internal_secret, owner_id: user_owner_id)
      Secret.create(resource_id: internal_secret, value: 'secret')
      Rails.cache.clear
    end
    it "secret is not saved in Redis if not under /data during create" do
      post("/secrets/#{internal_secret.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge(payload))
      expect(Rails.cache.read(internal_secret.split(':')[2])).to be_nil
    end

    it "secret is not saved in Redis if not under /data during show" do
      get("/secrets/#{internal_secret.gsub(':', '/')}", env: token_auth_header(role: admin_user))
      expect(Rails.cache.read(internal_secret.split(':')[2])).to be_nil
    end

    it "secret is not saved in Redis if under /data during create" do
      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge(payload))
      expect(Rails.cache.read(data_var_id.split(':')[2])).to be_nil
    end

    it "secret is saved in Redis if under /data during show" do
      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))
      expect(Rails.cache.read('/secrets/' + data_var_id.split(':')[2])).to_not be_nil
    end

    it "secret is updated in Redis if under /data and exists in Redis during create" do
      Rails.cache.write('/secrets/' + data_var_id.split(':')[2], 'secret')
      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge(payload))
      expect(Rails.cache.read('/secrets/' + data_var_id.split(':')[2])).to eq('new-secret')
    end
  end

  context "Secrets are read from Redis when appropriate" do
    let(:data_var_id) { "#{account}:variable:data/conjur_secret" }
    before do
      init_slosilo_keys("rspec")
      Role.find_or_create(role_id: user_owner_id)
      Resource.create(resource_id: data_var_id, owner_id: user_owner_id)
      Secret.create(resource_id: data_var_id, value: 'secret')
      Rails.cache.clear
    end

    it "secret is read from Redis and not from DB" do
      Rails.cache.write('/secrets/' + data_var_id.split(':')[2], 'secret')
      expect(Rails.cache).to receive(:read).with('/secrets/' + data_var_id.split(':')[2]).and_call_original
      expect(Rails.cache).to receive(:read).with('/secrets/' + data_var_id.split(':')[2] + '/mime_type').and_call_original
      expect_any_instance_of(Resource).to_not receive(:secret)

      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))
    end

    it "secret is not read from Redis when version requested" do
      Rails.cache.write('/secrets/' + data_var_id.split(':')[2], 'secret')
      expect(Rails.cache).to_not receive(:read)
      expect_any_instance_of(Resource).to receive(:secret)

      get("/secrets/#{data_var_id.gsub(':', '/')}?version=3", env: token_auth_header(role: admin_user))
    end
  end

  context "SecretsController works despite Redis malfunction" do
    let(:data_var_id) { "#{account}:variable:data/conjur_secret" }
    let(:payload) { {'RAW_POST_DATA' => 'new-secret'} }
    before do
      init_slosilo_keys("rspec")
      Role.find_or_create(role_id: user_owner_id)
      Resource.create(resource_id: data_var_id, owner_id: user_owner_id)
      Secret.create(resource_id: data_var_id, value: 'secret')
      Rails.cache.clear
    end

    it "Show succeeds when Redis throws exception" do
      expect(Rails.cache).to receive(:read).and_raise(ApplicationController::ServiceUnavailable)

      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))

      expect(response).to be_ok
      expect(response.body).to eq('secret')
    end

    it "Create succeeds when Redis throws exception" do
      Rails.cache.write('/secrets/' + data_var_id.split(':')[2], 'secret')
      expect(Rails.cache).to receive(:write).and_raise(ApplicationController::ServiceUnavailable)

      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge(payload))

      expect(response.status).to eq(201)
    end

    it "Show succeeds when Redis returns nil" do
      expect(Rails.cache).to receive(:read).and_return(nil)

      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))

      expect(response).to be_ok
      expect(response.body).to eq('secret')
    end

    it "Create succeeds when Redis throws exception" do
      expect(Rails.cache).to receive(:read).and_return(nil) # Create reads before it creating

      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge(payload))

      expect(response.status).to eq(201)
    end
  end

end

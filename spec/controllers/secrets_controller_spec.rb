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

    it 'pCloud fetch is updated only for correct use case and only once' do
      # Check the PCloud fetch secret is empty
      expect(Secret[resource_id: "#{account}:variable:internal/telemetry/first_pcloud_fetch"]).to be_nil

      # fetch show with user
      get("/secrets/#{pcloud_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))
      expect(Secret[resource_id: "#{account}:variable:internal/telemetry/first_pcloud_fetch"]).to be_nil

      # fetch show for non pCloud secret
      get("/secrets/#{non_pcloud_var_id.gsub(':', '/')}", env: token_auth_header(role: my_host))
      expect(Secret[resource_id: "#{account}:variable:internal/telemetry/first_pcloud_fetch"]).to be_nil

      # fetch batch with user
      get("/secrets?variable_ids=#{pcloud_var_id}", env: token_auth_header(role: admin_user))
      expect(Secret[resource_id: "#{account}:variable:internal/telemetry/first_pcloud_fetch"]).to be_nil

      # fetch batch for non pCloud secret
      get("/secrets?variable_ids=#{non_pcloud_var_id}", env: token_auth_header(role: my_host))
      expect(Secret[resource_id: "#{account}:variable:internal/telemetry/first_pcloud_fetch"]).to be_nil

      # fetch show with host and pCloud secret
      get("/secrets/#{pcloud_var_id.gsub(':', '/')}", env: token_auth_header(role: my_host))
      expect(Secret[resource_id: "#{account}:variable:internal/telemetry/first_pcloud_fetch"]).to_not be_nil
      secret_value = Secret[resource_id: "#{account}:variable:internal/telemetry/first_pcloud_fetch"]

      # Subsequent calls don't change the value
      get("/secrets/#{pcloud_var_id.gsub(':', '/')}", env: token_auth_header(role: my_host))
      expect(Secret[resource_id: "#{account}:variable:internal/telemetry/first_pcloud_fetch"]).to eq(secret_value)
      get("/secrets?variable_ids=#{pcloud_var_id}", env: token_auth_header(role: my_host))
      expect(Secret[resource_id: "#{account}:variable:internal/telemetry/first_pcloud_fetch"]).to eq(secret_value)
      get("/secrets?variable_ids=#{non_pcloud_var_id}", env: token_auth_header(role: my_host))
      expect(Secret[resource_id: "#{account}:variable:internal/telemetry/first_pcloud_fetch"]).to eq(secret_value)
      get("/secrets?variable_ids=#{non_pcloud_var_id}", env: token_auth_header(role: admin_user))
      expect(Secret[resource_id: "#{account}:variable:internal/telemetry/first_pcloud_fetch"]).to eq(secret_value)
    end
  end

  ### Redis
  def read_from_redis(key)
    Slosilo::EncryptedAttributes.decrypt(Rails.cache.read(key), aad: key)
  end
  def write_into_redis(key, value)
    Rails.cache.write(key, Slosilo::EncryptedAttributes.encrypt(value, aad: key))
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
      expect(read_from_redis(internal_secret)).to be_nil
    end

    it "secret is not saved in Redis if not under /data during show" do
      get("/secrets/#{internal_secret.gsub(':', '/')}", env: token_auth_header(role: admin_user))
      expect(read_from_redis(internal_secret)).to be_nil
    end

    it "secret is not saved in Redis if under /data during create" do
      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge(payload))
      expect(read_from_redis(data_var_id)).to be_nil
    end

    it "secret is saved in Redis if under /data during show" do
      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))
      expect(read_from_redis(data_var_id)).to_not be_nil
    end

    it "secret is updated in Redis if under /data and exists in Redis during create" do
      write_into_redis(data_var_id, 'secret')
      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge(payload))
      expect(read_from_redis(data_var_id)).to eq('new-secret')
    end
  end

  context "Secrets are read from Redis when appropriate" do
    let(:data_var_id) { "#{account}:variable:data/conjur_secret" }
    let(:resource_data_id) { "secrets/resource/#{account}:variable:data/conjur_secret" }
    let(:admin_user_id) { "user/#{account}:user:admin"}
    before do
      init_slosilo_keys("rspec")
      Role.find_or_create(role_id: user_owner_id)
      Resource.create(resource_id: data_var_id, owner_id: user_owner_id)
      Secret.create(resource_id: data_var_id, value: 'secret')
      Rails.cache.clear
    end

    it "secret is read from Redis and not from DB" do
      write_into_redis(data_var_id, 'secret')
      expect(Rails.cache).to receive(:read).with("getSecret/counter").and_return(0)
      expect(Rails.cache).to receive(:read).with(admin_user_id).and_call_original
      expect(Rails.cache).to receive(:read).with(resource_data_id).and_call_original
      expect(Rails.cache).to receive(:read).with(data_var_id).and_call_original
      expect(Rails.cache).to receive(:read).with(data_var_id + '/mime_type').and_call_original
      expect_any_instance_of(Resource).to_not receive(:secret)

      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))
    end
  end

  context "SecretsController works despite Redis malfunction" do
    let(:data_var_id) { "#{account}:variable:data/conjur_secret" }
    let(:resource_data_id) { "secrets/resource/#{account}:variable:data/conjur_secret" }
    let(:payload) { {'RAW_POST_DATA' => 'new-secret'} }
    let(:admin_user_id) { "user/#{account}:user:admin"}
    before do
      init_slosilo_keys("rspec")
      Role.find_or_create(role_id: user_owner_id)
      Resource.create(resource_id: data_var_id, owner_id: user_owner_id)
      Secret.create(resource_id: data_var_id, value: 'secret')
    end


    it "Show succeeds when Redis throws exception" do
      expect(Rails.cache).to receive(:read).with("getSecret/counter").and_return(0)
      expect(Rails.cache).to receive(:read).with(resource_data_id).and_call_original
      expect(Rails.cache).to receive(:read).with(admin_user_id).and_call_original
      expect(Rails.cache).to receive(:read).exactly(3).times.and_raise(ApplicationController::ServiceUnavailable)

      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))

      expect(response).to be_ok
      expect(response.body).to eq('secret')
    end

    it "Create succeeds when Redis throws exception" do
      write_into_redis(data_var_id, 'secret')
      expect(Rails.cache).to receive(:read).with(admin_user_id).and_call_original
      expect(Rails.cache).to receive(:read).with(data_var_id).and_call_original
      expect(Rails.cache).to receive(:read).with("rspec:variable:data/conjur_secret/mime_type").and_call_original
      expect(Rails.cache).to receive(:write).at_least(:once).and_raise(ApplicationController::ServiceUnavailable)

      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge(payload))

      expect(response.status).to eq(201)
    end

    it "Show succeeds when Redis returns nil" do
      expect(Rails.cache).to receive(:read).with("getSecret/counter").and_return(0)
      expect(Rails.cache).to receive(:read).exactly(6).times.and_return(nil)

      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))

      expect(response).to be_ok
      expect(response.body).to eq('secret')
    end

    it "Create succeeds when Redis returns nil" do
      expect(Rails.cache).to receive(:read).exactly(5).times.and_return(nil) # Create reads before it creating

      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge(payload))

      expect(response.status).to eq(201)
    end
  end

  context "Redis with version" do
    let(:data_var_id) { "#{account}:variable:data/conjur_secret" }
    let(:resource_data_id) { "secrets/resource/#{account}:variable:data/conjur_secret" }
    let(:admin_user_id) { "user/#{account}:user:admin"}
    before do
      init_slosilo_keys("rspec")
      Role.find_or_create(role_id: user_owner_id)
      Resource.create(resource_id: data_var_id, owner_id: user_owner_id)
      Rails.cache.clear
    end
    it "secret is read from Redis with and without version" do
      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge({'RAW_POST_DATA' => 'secret_1'}))
      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge({'RAW_POST_DATA' => 'secret_2'}))
      get("/secrets/#{data_var_id.gsub(':', '/')}?version=1", env: token_auth_header(role: admin_user)) # Should get the secret into Redis
      get("/secrets/#{data_var_id.gsub(':', '/')}?version=2", env: token_auth_header(role: admin_user)) # Should get the secret into Redis
      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user)) # Should get the secret into Redis

      expect(Rails.cache).to receive(:read).with("getSecret/counter").exactly(3).and_return(0)
      expect(Rails.cache).to receive(:read).with(admin_user_id).exactly(3).and_call_original
      expect(Rails.cache).to receive(:read).with(resource_data_id).exactly(3).and_call_original
      expect(Rails.cache).to receive(:read).with(data_var_id + "?version=1").and_call_original
      expect(Rails.cache).to receive(:read).with(data_var_id + "/mime_type").and_call_original
      expect_any_instance_of(Resource).to_not receive(:secret)
      get("/secrets/#{data_var_id.gsub(':', '/')}?version=1", env: token_auth_header(role: admin_user))
      expect(response.body).to eq('secret_1')

      expect(Rails.cache).to receive(:read).with(data_var_id + "?version=2").and_call_original
      expect(Rails.cache).to receive(:read).with(data_var_id + "/mime_type").and_call_original
      expect_any_instance_of(Resource).to_not receive(:secret)
      get("/secrets/#{data_var_id.gsub(':', '/')}?version=2", env: token_auth_header(role: admin_user))
      expect(response.body).to eq('secret_2')

      expect(Rails.cache).to receive(:read).with(data_var_id).and_call_original
      expect(Rails.cache).to receive(:read).with(data_var_id + "/mime_type").and_call_original
      expect_any_instance_of(Resource).to_not receive(:secret)
      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))
      expect(response.body).to eq('secret_2')
    end
  end

  context "batch fetch" do
    let(:data_var_id) { "#{account}:variable:data/conjur_secret" }
    let(:internal_secret) { "#{account}:variable:internal/secret" }
    let(:empty_secret) { "#{account}:variable:data/empty_secret" }
    let(:admin_user_id) { "user/#{account}:user:admin"}
    let(:secret) { "secret" }

    before do
      init_slosilo_keys("rspec")
      Role.find_or_create(role_id: user_owner_id)
      Rails.cache.clear
    end

    it "batch fetch with redis" do
      Resource.create(resource_id: data_var_id, owner_id: user_owner_id)
      Secret.create(resource_id: data_var_id, value: secret)
      # Call before value is in redis

      expect(Rails.cache).to receive(:read).with(data_var_id).and_call_original
      expect(Rails.cache).to receive(:read).with(data_var_id + "/mime_type").and_call_original
      expect(Rails.cache).to receive(:read).with(admin_user_id).and_call_original
      expect_any_instance_of(Resource).to receive(:last_secret).and_call_original
      expect(Rails.cache).to receive(:write).with(data_var_id, anything).and_call_original
      expect(Rails.cache).to receive(:write).with(admin_user_id,anything).and_call_original
      get("/secrets?variable_ids=#{data_var_id}", env: token_auth_header(role: admin_user))
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq({data_var_id => secret})
      # Call after value is in redis
      expect(Rails.cache).to receive(:read).with(data_var_id).and_call_original
      expect(Rails.cache).to receive(:read).with(admin_user_id).and_call_original
      expect(Rails.cache).to receive(:read).with(data_var_id + "/mime_type").and_call_original
      expect_any_instance_of(Resource).to_not receive(:last_secret).and_call_original
      expect(Rails.cache).to_not receive(:write).with(data_var_id).and_call_original
      get("/secrets?variable_ids=#{data_var_id}", env: token_auth_header(role: admin_user))
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq({data_var_id => secret})
    end

    it "batch fetch without redis" do
      Resource.create(resource_id: internal_secret, owner_id: user_owner_id)
      Secret.create(resource_id: internal_secret, value: secret)
      expect(Rails.cache).to_not receive(:read).with(internal_secret)
      expect(Rails.cache).to_not receive(:read).with(internal_secret + "/mime_type")
      expect_any_instance_of(Resource).to receive(:last_secret).and_call_original
      get("/secrets?variable_ids=#{internal_secret}", env: token_auth_header(role: admin_user))

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq({internal_secret => secret})
    end

    it "batch fetch for empty secret" do
      Resource.create(resource_id: empty_secret, owner_id: user_owner_id)
      expect(Rails.cache).to receive(:read).with(empty_secret).and_call_original
      expect(Rails.cache).to receive(:read).with(empty_secret + "/mime_type").and_call_original
      expect(Rails.cache).to receive(:read).with("user/rspec:user:admin").and_call_original
      allow_any_instance_of(Resource).to receive(:last_secret).and_call_original
      get("/secrets?variable_ids=#{empty_secret}", env: token_auth_header(role: admin_user))

      expect(response.status).to eq(404)
    end

    it "batch fetch combines secrets" do
      Resource.create(resource_id: data_var_id, owner_id: user_owner_id)
      Secret.create(resource_id: data_var_id, value: secret)
      Resource.create(resource_id: internal_secret, owner_id: user_owner_id)
      Secret.create(resource_id: internal_secret, value: secret)
      Resource.create(resource_id: empty_secret, owner_id: user_owner_id)

      # All secrets
      expect(Rails.cache).to receive(:read).with(data_var_id).and_call_original
      expect(Rails.cache).to receive(:read).with(data_var_id + "/mime_type").and_call_original
      expect(Rails.cache).to_not receive(:read).with(internal_secret)
      expect(Rails.cache).to_not receive(:read).with(internal_secret + "/mime_type")
      expect(Rails.cache).to receive(:read).with(empty_secret).and_call_original
      expect(Rails.cache).to receive(:read).with(empty_secret + "/mime_type").and_call_original
      get("/secrets?variable_ids=#{data_var_id},#{internal_secret},#{empty_secret}", env: token_auth_header(role: admin_user))

      expect(response.status).to eq(404)

      # Non empty secrets
      expect(Rails.cache).to receive(:read).with(data_var_id).and_call_original
      expect(Rails.cache).to receive(:read).with(data_var_id + "/mime_type").and_call_original
      expect(Rails.cache).to_not receive(:read).with(internal_secret)
      expect(Rails.cache).to_not receive(:read).with(internal_secret + "/mime_type")
      get("/secrets?variable_ids=#{data_var_id},#{internal_secret}", env: token_auth_header(role: admin_user))

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq({internal_secret => secret, data_var_id => secret})
    end
  end

end

# frozen_string_literal: true

require 'spec_helper'

describe SecretsController, type: :request do

  let(:account) { "rspec" }
  let(:user_owner_id) { 'rspec:user:admin' }
  let(:host_id) { 'rspec:host:hosty' }
  let(:admin_user) { Role.find_or_create(role_id: user_owner_id) }
  let(:my_host) { Role.find_or_create(role_id: host_id) }

  context 'pCloud secrets fetch monitoring' do
    let(:pcloud_var_id) { "#{account}:variable:data/vault/pCloud_fetch_pcloud_secret" }
    let(:non_pcloud_var_id) { "#{account}:variable:data/pCloud_fetch_conjur_secret" }
    let(:access_variable_id) { "#{account}:variable:internal/telemetry/first_pcloud_fetch" }
    before do
      init_slosilo_keys("rspec")
      Role.find_or_create(role_id: user_owner_id)
      Role.find_or_create(role_id: host_id)
      Resource.create(resource_id: access_variable_id, owner_id: user_owner_id)
      Resource.create(resource_id: pcloud_var_id, owner_id: user_owner_id)
      Secret.create(resource_id: pcloud_var_id, value: 'secret')
      Resource.create(resource_id: non_pcloud_var_id, owner_id: user_owner_id)
      Secret.create(resource_id: non_pcloud_var_id, value: 'secret')
      Permission.create(
        resource_id: non_pcloud_var_id,
        privilege: "execute",
        role_id: host_id
      )
      Permission.create(
        resource_id: pcloud_var_id,
        privilege: "execute",
        role_id: host_id
      )
      described_class.set_pcloud_access(nil)
    end

    it 'pCloud fetch is updated only for correct use case and only once' do
      # Check the PCloud fetch secret exists and is empty
      expect(Resource[resource_id: access_variable_id]).to_not be_nil
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

    it "secret is deleted in Redis if under /data and exists in Redis during create" do
      write_into_redis(data_var_id, 'secret')
      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge(payload))
      expect(read_from_redis(data_var_id)).to eq(nil)
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
      expect(Rails.cache).to receive(:read).with(resource_data_id).and_call_original
      expect(Rails.cache).to receive(:read).with(admin_user_id).and_call_original
      expect(Rails.cache).to receive(:read).exactly(3).times.and_raise(ApplicationController::ServiceUnavailable)

      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))

      expect(response).to be_ok
      expect(response.body).to eq('secret')
    end

    it "Create fails when Redis throws exception" do
      write_into_redis(data_var_id, 'secret')
      expect(Rails.cache).to receive(:read).with(admin_user_id).and_call_original
      expect(Rails.cache).to receive(:delete).with(data_var_id).at_least(:once).and_raise(ApplicationController::ServiceUnavailable)

      post("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user).merge(payload))

      expect(response.status).to eq(503)
    end

    it "Show succeeds when Redis returns nil" do
      expect(Rails.cache).to receive(:read).exactly(6).times.and_return(nil)

      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))

      expect(response).to be_ok
      expect(response.body).to eq('secret')
    end

    it "Create succeeds when Redis returns nil" do
      expect(Rails.cache).to receive(:read).exactly(3).times.and_return(nil) # Create reads before it creating

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

  context "When the user is edge" do
    let(:secret_resource) { "#{account}:variable:data/my_secret" }
    let(:edge_host_id) {"#{account}:host:edge/edge-1234/edge-host-1234"}
    let(:secret_resource) { "#{account}:variable:data/my_secret" }
    let(:other_edge_host_id) {"#{account}:host:data/other"}
    let(:my_host) { Role.find_or_create(role_id: edge_host_id) }

    before do
      init_slosilo_keys(account)
      @current_user = create_host(edge_host_id, admin_user)
      @other_user = create_host(other_edge_host_id, admin_user)
      Resource.create(resource_id: secret_resource, owner_id: user_owner_id)
      Secret.create(resource_id: secret_resource, value: 'secret')
    end

    context "and he tries to get secret" do
      before do
        Role.create(role_id: "#{account}:group:edge/edge-hosts")
        RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: edge_host_id, admin_option: false, ownership: false)
        Rails.cache.clear
      end
      it "Successfully gets the secret" do
        get("/secrets/#{secret_resource.gsub(':', '/')}", env: token_auth_header(role: @current_user, is_user: false))
        expect(response.code).to eq("200")
        expect(response.body).to eq("secret")
      end
    end

    context "and the edge is invalid and tries to get secret" do
      before do
        Rails.cache.clear
      end
      it "Return Not-Found" do
        get("/secrets/#{secret_resource.gsub(':', '/')}", env: token_auth_header(role: @other_user, is_user: false))
        expect(response.code).to eq("404")
      end
    end

    context "get resource object handling" do
      let(:secret_resource) { "#{account}:variable:data/my_secret2" }
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
      let(:host_id) {"#{account}:host:data/other1"}

      before do
        init_slosilo_keys(account)
        @current_user = create_host(host_id, admin_user)
        Secret.create(resource_id: secret_resource, value: 'secret')
        Permission.create(
          resource_id: secret_resource,
          privilege: "read",
          role_id: host_id
        )

      end

      context 'when resource is not visible to current user' do
        it 'raises an Exceptions::RecordNotFound error' do
          write_into_redis(secret_resource, 'secret')
          get("/secrets/#{secret_resource.gsub(':', '/')}", env: token_auth_header(role: current_user))

          expect(response.code).to eq("404")
        end
      end


    end
  end

  context "Telemetry is called for get secret" do
    around do |ex|
      orig_metrics = Monitoring::Prometheus.metrics
      Monitoring::Prometheus.setup(registry: Prometheus::Client::Registry.new, metrics: [Monitoring::Metrics::ApiRequestCounter.new])
      ex.run
      Monitoring::Prometheus.setup(registry: Prometheus::Client::Registry.new, metrics: orig_metrics)
    end

    let(:data_var_id) { "#{account}:variable:data/conjur_secret" }
    before do
      init_slosilo_keys("rspec")
      Role.find_or_create(role_id: user_owner_id)
      Resource.create(resource_id: data_var_id, owner_id: user_owner_id)
      Rails.cache.clear
    end

    it "calls telemetry as many times as get secrets is called" do
      expect(Rails.cache).to receive(:increment).with("getSecret/counter", {:expires_in=>nil}).twice.and_return(1)
      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))
      get("/secrets/#{data_var_id.gsub(':', '/')}", env: token_auth_header(role: admin_user))
    end
  end
end

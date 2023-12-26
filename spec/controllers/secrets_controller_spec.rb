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
end

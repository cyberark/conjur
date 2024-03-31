require 'spec_helper'
require 'monitoring/query_helper'
Dir.glob(Rails.root + 'lib/monitoring/metrics/policy_*.rb', &method(:require))

describe 'policy metrics', type: :request  do

  before do
    @resource_metric = Monitoring::Metrics::PolicyResourceGauge.new
    @role_metric = Monitoring::Metrics::PolicyRoleGauge.new
    pubsub.unsubscribe(policy_load_event_name)

    # Clear and setup the Prometheus client store
    Monitoring::Prometheus.setup(
      registry: Prometheus::Client::Registry.new,
      metrics: metrics
    )

    Slosilo["authn:rspec"] ||= Slosilo::Key.new
  end

  def headers_with_auth(payload)
    token_auth_header.merge({ 'RAW_POST_DATA' => payload })
  end

  let(:registry) { Monitoring::Prometheus.registry }

  let(:pubsub) { Monitoring::PubSub.instance }

  let(:metrics) { [ @resource_metric, @role_metric ] }

  let(:policy_load_event_name) { 'conjur.policy_loaded' }

  let(:policies_url) { '/policies/conjur/policy/data' }

  let(:current_user) { Role.find_or_create(role_id: 'conjur:user:admin') }

  let(:token_auth_header) do
    bearer_token = Slosilo["authn:rspec"].signed_token(current_user.login)
    token_auth_str =
      "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
    { 'HTTP_AUTHORIZATION' => token_auth_str }
  end

  context 'when a policy is loaded' do

    xit 'publishes a policy load event (POST)' do
      expect(Monitoring::PubSub.instance).to receive(:publish).with(policy_load_event_name).once

      post(policies_url, env: headers_with_auth('[!variable test]'))
    end

    xit 'publishes a policy load event (PUT)' do
      expect(Monitoring::PubSub.instance).to receive(:publish).with(policy_load_event_name).once

      put(policies_url, env: headers_with_auth('[!variable test]'))
    end

    xit 'publishes a policy load event (PATCH)' do
      expect(Monitoring::PubSub.instance).to receive(:publish).with(policy_load_event_name).once

      patch(policies_url, env: headers_with_auth('[!variable test]'))
    end

    xit 'calls update on the correct metrics' do
      expect(@resource_metric).to receive(:update)
      expect(@role_metric).to receive(:update)

      post(policies_url, env: headers_with_auth('[!variable test]'))
    end

    xit 'updates the registry' do
      resources_before = registry.get(@resource_metric.metric_name).get(labels: { kind: 'host', tenant_id: 'mytenant'})
      roles_before = registry.get(@role_metric.metric_name).get(labels: { kind: 'host' })

      post(policies_url, env: headers_with_auth('[!host test]'))

      resources_after = registry.get(@resource_metric.metric_name).get(labels: { kind: 'host', tenant_id: 'mytenant' })
      roles_after = registry.get(@role_metric.metric_name).get(labels: { kind: 'host' })

      expect(resources_after - resources_before).to eql(1.0)
      expect(roles_after - roles_before).to eql(1.0)
    end
  end
end

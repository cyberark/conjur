require 'spec_helper'
require 'monitoring/query_helper'
Dir.glob(Rails.root + 'lib/monitoring/metrics/policy_*.rb', &method(:require))

describe 'policy metrics', type: :request  do

  before do
    pubsub.unsubscribe('conjur.policy_loaded')
    pubsub.unsubscribe('conjur.resource_count_update')
    pubsub.unsubscribe('conjur.role_count_update')

    @resource_metric = Monitoring::Metrics::PolicyResourceGauge.new
    @role_metric = Monitoring::Metrics::PolicyRoleGauge.new

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

  let(:metrics) { [ @resource_metric, @role_metric ] }

  let(:pubsub) { Monitoring::PubSub.instance }

  let(:policy_load_event_name) { 'conjur.policy_loaded' }

  let(:policies_url) { '/policies/rspec/policy/root' }

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  let(:token_auth_header) do
    bearer_token = Slosilo["authn:rspec"].signed_token(current_user.login)
    token_auth_str =
      "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
    { 'HTTP_AUTHORIZATION' => token_auth_str }
  end

  context 'when a policy is loaded' do

    it 'publishes a policy load event (POST)' do
      expect(Monitoring::PubSub.instance).to receive(:publish).with(policy_load_event_name).and_call_original

      expect(Monitoring::PubSub.instance).to receive(:publish).with(@resource_metric.sub_event_name)
      expect(Monitoring::PubSub.instance).to receive(:publish).with(@role_metric.sub_event_name)

      post(policies_url, env: headers_with_auth('[!variable test]'))
    end

    it 'publishes a policy load event (PUT)' do
      expect(Monitoring::PubSub.instance).to receive(:publish).with(policy_load_event_name).and_call_original

      expect(Monitoring::PubSub.instance).to receive(:publish).with(@resource_metric.sub_event_name)
      expect(Monitoring::PubSub.instance).to receive(:publish).with(@role_metric.sub_event_name)

      put(policies_url, env: headers_with_auth('[!variable test]'))
    end

    it 'publishes a policy load event (PATCH)' do
      expect(Monitoring::PubSub.instance).to receive(:publish).with(policy_load_event_name).and_call_original

      expect(Monitoring::PubSub.instance).to receive(:publish).with(@resource_metric.sub_event_name)
      expect(Monitoring::PubSub.instance).to receive(:publish).with(@role_metric.sub_event_name)

      patch(policies_url, env: headers_with_auth('[!variable test]'))
    end

    it 'calls update on the correct metrics' do
      expect(@resource_metric).to receive(:update)
      expect(@role_metric).to receive(:update)

      post(policies_url, env: headers_with_auth('[!variable test]'))
    end

    it 'updates the registry' do
      resources_before = registry.get(@resource_metric.metric_name).get(labels: { kind: 'group' })
      roles_before = registry.get(@role_metric.metric_name).get(labels: { kind: 'group' })

      post(policies_url, env: headers_with_auth('[!group test]'))

      resources_after = registry.get(@resource_metric.metric_name).get(labels: { kind: 'group' })
      roles_after = registry.get(@role_metric.metric_name).get(labels: { kind: 'group' })

      expect(resources_after - resources_before).to eql(1.0)
      expect(roles_after - roles_before).to eql(1.0)
    end

  end

  context 'when multiple policies are loaded' do

    # Revisit this test when update throttling has been implemented
    xit 'throttles policy events' do
      expect(@resource_metric).to receive(:update).at_most(2).times
      post(policies_url, env: headers_with_auth('[!variable test1]'))
      post(policies_url, env: headers_with_auth('[!variable test2]'))
      post(policies_url, env: headers_with_auth('[!variable test3]'))
      post(policies_url, env: headers_with_auth('[!variable test4]'))
      post(policies_url, env: headers_with_auth('[!variable test5]'))
    end
    
  end
end

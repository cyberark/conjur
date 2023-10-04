require 'spec_helper'
require 'monitoring/query_helper'
require 'monitoring/metrics/authenticator_gauge'

describe 'authenticator metrics', type: :request  do

  before do
    @authenticator_metric = Monitoring::Metrics::AuthenticatorGauge.new
    pubsub.unsubscribe(@authenticator_metric.sub_event_name)


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

  let(:metrics) { [ @authenticator_metric ] }

  let(:pubsub) { Monitoring::PubSub.instance }

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
      expect(Monitoring::PubSub.instance).to receive(:publish).with(@authenticator_metric.sub_event_name)

      post(policies_url, env: headers_with_auth('[!variable test]'))
    end

    it 'publishes a policy load event (PUT)' do
      expect(Monitoring::PubSub.instance).to receive(:publish).with(@authenticator_metric.sub_event_name)

      put(policies_url, env: headers_with_auth('[!variable test]'))
    end

    it 'publishes a policy load event (PATCH)' do
      expect(Monitoring::PubSub.instance).to receive(:publish).with(@authenticator_metric.sub_event_name)

      patch(policies_url, env: headers_with_auth('[!variable test]'))
    end

    it 'calls update on the correct metrics' do
      expect(@authenticator_metric).to receive(:update)

      post(policies_url, env: headers_with_auth('[!variable test]'))
    end

    it 'updates the registry' do
      authenticators_before = registry.get(@authenticator_metric.metric_name).get(labels: { type: 'authn-jwt', status: 'configured' })
      post(policies_url, env: headers_with_auth(
        <<~POLICY
        - !policy
           id: conjur/authn-jwt/sysadmins
           body:
            - !webservice 

            - !group
              id: clients

            - !permit
              resource: !webservice
              privilege: [ read, authenticate ]
              role: !group clients
      POLICY
        ))

      authenticators_after = registry.get(@authenticator_metric.metric_name).get(labels: { type: 'authn-jwt', status: 'configured' })

      expect(authenticators_after - authenticators_before).to eql(1.0)
    end

    it 'trims the authenticator service id' do
      authenticators = ['authn', 'authn-iam/some-service/id', 'authn-oidc/some/nested/service-id', 'authn-oidc/some/other/service-id']
      authenticator_counts = @authenticator_metric.get_authenticator_counts(authenticators)

      expect(authenticator_counts['authn']).to eql(1)
      expect(authenticator_counts['authn-iam']).to eql(1)
      expect(authenticator_counts['authn-oidc']).to eql(2)
    end

  end
end

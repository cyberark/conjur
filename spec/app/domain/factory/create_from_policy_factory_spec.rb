# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Factory::CreateFromPolicyFactory) do
  let(:rest_client) { spy(RestClient) }
  let(:factory) { Factory::CreateFromPolicyFactory.new(http: rest_client) }

  describe('.call') do
    # let(:factory_template) { JSON.parse(Base64.decode64(Factory::Templates::Core::User.data)) }
    context 'when request is missing attributes' do
      it 'fails with error' do
        expect {
          factory.call(
            factory_template: JSON.parse(Base64.decode64(Factory::Templates::Core::User.data)),
            request_body: { 'id' => 'foo' },
            account: 'cucumber',
            authorization: 'bar'
          )
        }.to raise_error(RuntimeError, "The following JSON attributes are missing: 'branch'")
      end
    end
    context 'when request is missing nested attributes' do
      it 'fails with error' do
        expect {
          factory.call(
            factory_template: JSON.parse(Base64.decode64(Factory::Templates::Authenticators::AuthnOidc.data)),
            request_body: {
              'service-id' => 'foo',
              'variables' => {
                'provider-uri' => 'foo',
                'client-id' => 'bar',
                'client-secret' => 'baz'
              }
            },
            account: 'cucumber',
            authorization: 'bar'
          )
        }.to raise_error(RuntimeError, "The following JSON attributes are missing: '/variables/claim-mapping'")
      end
    end

    context 'when policy factory is only a policy' do
      it 'loads the appropriate policy' do
        factory.call(
          factory_template: JSON.parse(Base64.decode64(Factory::Templates::Core::User.data)),
          request_body: { 'id' => 'foo', 'branch' => 'bar' },
          account: 'cucumber',
          authorization: 'bar'
        )
        expect(rest_client).to have_received(:post).with('http://localhost:3000/policies/cucumber/policy/bar', "- !user\n  id: foo\n  ", {"Authorization"=>"bar"})
      end
    end

    context 'when policy factory is policy and variables' do
      let(:factory_template) { JSON.parse(Base64.decode64(Factory::Templates::Authenticators::AuthnOidc.data)) }
      before do
        factory.call(
          factory_template: factory_template,
          request_body: {
            'service-id' => 'foo',
            'variables' => {
              'provider-uri' => 'foo',
              'client-id' => 'bar',
              'client-secret' => 'baz',
              'claim-mapping' => 'bing'
            }
          },
          account: 'cucumber',
          authorization: 'bar'
        )
      end
      it 'loads the appropriate policy' do
        expect(rest_client).to have_received(:post).with(
          'http://localhost:3000/policies/cucumber/policy/conjur/authn-oidc',
          "- !policy\n  id: foo\n  body:\n  - !webservice\n\n  - !variable provider-uri\n  - !variable client-id\n  - !variable client-secret\n\n  # URI of Conjur instance\n  - !variable redirect_uri\n\n  # Defines the JWT claim to use as the Conjur identifier\n  - !variable claim-mapping\n\n  - !group authenticatable\n    annotations:\n      description: Group with permission to authenticate using this authenticator\n\n  - !permit\n    role: !group authenticatable\n    privilege: [ read, authenticate ]\n    resource: !webservice\n\n  - !webservice status\n    annotations:\n      description: Web service for checking authenticator status\n\n  - !group\n    id: operators\n    annotations:\n      description: Group with permission to check the authenticator status\n\n  - !permit\n    role: !group operators\n    privilege: read\n    resource: !webservice status\n",
          { "Authorization"=>"bar" }
        )
      end
      it 'sets provider-id to the expected value' do
        expect(rest_client).to have_received(:post).with(
          'http://localhost:3000/secrets/cucumber/variable/conjur%2Fauthn-oidc%2Ffoo%2Fprovider-uri',
          'foo',
          { 'Authorization' => 'bar' }
        )
      end
      it 'sets client-id to the expected value' do
        expect(rest_client).to have_received(:post).with(
          'http://localhost:3000/secrets/cucumber/variable/conjur%2Fauthn-oidc%2Ffoo%2Fclient-id',
          'bar',
          { 'Authorization' => 'bar' }
        )
      end
      it 'sets client-secret to the expected value' do
        expect(rest_client).to have_received(:post).with(
          'http://localhost:3000/secrets/cucumber/variable/conjur%2Fauthn-oidc%2Ffoo%2Fclient-secret',
          'baz',
          { 'Authorization' => 'bar' }
        )
      end
      it 'sets claim-mapping to the expected value' do
        expect(rest_client).to have_received(:post).with(
          'http://localhost:3000/secrets/cucumber/variable/conjur%2Fauthn-oidc%2Ffoo%2Fclaim-mapping',
          'bing',
          { 'Authorization' => 'bar' }
        )
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'parallel'

DatabaseCleaner.strategy = :truncation

describe SecretsController, type: :request do
  let(:account) { 'rspec' }
  let(:test_policy) do
    <<~POLICY
      - !variable
        id: test
    POLICY
  end

  let(:admin_user) { Role.find_or_create(role_id: "#{account}:user:admin") }
  let(:policy_url) do
    "/policies/#{account}/policy/root"
  end

  let(:secret_id) { "test" }
  let(:role_actual) { Role.find_or_create(role_id: role_resource_id) }

  let(:secret_url) { "/secrets/#{account}/variable/#{secret_id}" }
  let(:secret_value) { "test" }
  let(:secret_mime_type) { nil }

  let(:read_permitted) { true }
  let(:update_permitted) { true }
  let(:execute_permitted) { true }

  let(:secret_resource_id) { "#{account}:variable:#{secret_id}" }
  let(:role_resource_id) { "#{account}:user:admin" }

  let(:role_double) do
    instance_double(
      Role,
      id: role_resource_id,
      role_id: role_resource_id
    )
  end

  let(:resource_double) do
    instance_double(
      Resource,
      id: secret_resource_id,
      kind: 'variable',
      resource_id: secret_resource_id,
      identifier: secret_id
    ).tap do |resource_double|
      allow(resource_double)
        .to receive(:visible_to?)
        .with(role_double)
        .and_return(read_permitted)

      allow(resource_double)
        .to receive(:secret)
        .and_return(secret_double)

      allow(resource_double)
        .to receive(:annotation)
        .with('conjur/mime_type')
        .and_return(secret_mime_type)

      allow(resource_double)
        .to receive(:annotations)
        .and_return(resource_annotations)

      allow(resource_double)
        .to receive(:pk_hash)
        .and_return({ resource: secret_resource_id })

      allow(resource_double).to receive(:enforce_secrets_version_limit)
    end
  end

  let(:resource_annotations) { [] }

  let(:secret_double) do
    instance_double(
      Secret,
      value: secret_value
    )
  end

  let(:dynamic_secrets_enabled) { true }

  def load_secret
    post(
      secret_url,
      env: token_auth_header(role: role_actual).merge(
        { 'RAW_POST_DATA' => secret_value }
      )
    )
  end

  def view_secret
    get(
      secret_url,
      env: token_auth_header(role: role_actual)
    )
  end

  before do
    Slosilo["authn:#{account}"] ||= Slosilo::Key.new

    allow(Resource)
      .to receive(:[])
      .with(secret_resource_id)
      .and_return(resource_double)

    allow(Role)
      .to receive(:[])
      .with(role_resource_id)
      .and_return(role_double)

    allow(Secret)
      .to receive(:create)
      .with(
        resource_id: resource_double.id,
        value: secret_value
      )

    # We also want to allow all audit calls, but aren't concerned with these
    allow(Audit.logger).to receive(:log)

    # Enable update and execute permissions for the role
    allow(role_double)
      .to receive(:allowed_to?)
      .with(:update, resource_double)
      .and_return(update_permitted)

    allow(role_double)
      .to receive(:allowed_to?)
      .with(:execute, resource_double)
      .and_return(execute_permitted)

    # Dynamic secrets feature flag
    allow_any_instance_of(Conjur::FeatureFlags::Features)
      .to receive(:enabled?)
      .and_call_original

    allow_any_instance_of(Conjur::FeatureFlags::Features)
      .to receive(:enabled?)
      .with(:dynamic_secrets)
      .and_return(dynamic_secrets_enabled)
  end

  describe '#create' do
    # Tests that the controller catches an error that will occur when you are
    # making a write request and the psql user does not have the correct
    # permission.
    #
    # This is not specific to this controller.
    context 'when you do not have write privileges to the database'  do
      let(:secret_double) { nil }  # assure the create will be called

      before do
        allow(Secret)
          .to receive(:create)
          .and_raise(PG::InsufficientPrivilege)
      end

      it 'should return a 405 error' do
        load_secret

        expect(response.code).to eq("405")
        res = JSON.parse(response.body)

        expect(res["error"]["message"])
          .to eq("Write operations are not allowed")
      end
    end

    context 'when the secret is empty' do
      let(:secret_value) { nil }

      it 'should return an error' do
        load_secret
        expect(response.code).to eq("422")
        res = JSON.parse(response.body)

        expect(res["error"]["message"])
          .to eq("'value' may not be empty")
      end
    end

    context 'when the secret is dynamic' do
      let(:secret_value) { "test value" }
      let(:secret_id) { "data/dynamic/test" }
      let(:test_policy) do
        <<~POLICY
          - !variable
            id: data/dynamic/test
            annotations:
              dynamic/issuer: my-issuer
        POLICY
      end

      it 'should return an error' do
        load_secret
        expect(response.code).to eq("405")
        res = JSON.parse(response.body)

        expect(res["error"]["message"])
          .to eq(
            "adding a static secret to a dynamic secret variable is not allowed"
          )
      end

      context 'when dynamic secrets are not enabled' do
        let(:dynamic_secrets_enabled) { false }

        it 'is treated like a regular secret' do
          load_secret
          expect(response.code).to eq("201")
        end
      end
    end

    it 'should return a 201 status code' do
      load_secret
      expect(response.code).to eq("201")
    end

    it 'should not increase version when value did not change' do
      allow(Secret)
        .to receive(:create)
        .once
      load_secret
      load_secret
    end

    context 'secrets version increases' do
      let(:secret) { SecureRandom.hex(8) }

      it 'when value did change' do
        allow(Secret)
          .to receive(:create)
          .twice
        load_secret
        load_secret
      end
    end

  end

  describe '#show' do
    # Tests that the controller catches an error that will occur when you are
    # making a read request and the psql user does not have the correct
    # permission.
    #
    # This is not specific to this controller.
    context 'when you do not have Read privileges to the database'  do
      before do
        allow(Resource)
          .to receive(:[])
          .and_raise(PG::InsufficientPrivilege)
      end

      it 'should return a 405 status code' do
        view_secret

        expect(response.code).to eq("405")
        res = JSON.parse(response.body)

        expect(res["error"]["message"])
          .to eq("Read operations are not allowed")
      end
    end

    context 'when the requested secret does not exist' do
      before do
        allow(resource_double)
          .to receive(:secret)
          .and_return(nil)
      end

      it 'should return an error' do
        view_secret

        expect(response.code).to eq("404")
        res = JSON.parse(response.body)

        expect(res["error"]["message"])
          .to eq(
            "CONJ00076E Variable rspec:variable:test is empty or not found."
          )
      end
    end

    it 'should return a 200 status code' do
      view_secret
      expect(response.code).to eq("200")
    end

    it 'should return the secret' do
      view_secret
      expect(response.body).to eq(secret_value)
    end

    context 'when the secret is dynamic' do
      let(:secret_id) do
        'data/dynamic/test'
      end

      context 'when there is no issuer defined' do
        it 'returns an error' do
          view_secret
          expect(response.code).to eq("422")
          expect(response.body).to include('Issuer assigned to rspec:variable:data/dynamic/test was not found')
        end
      end

      context 'when the issuer is defined' do
        let(:issuer_id) { 'my-placeholder-issuer' }

        let(:resource_annotations) do
          [
            instance_double(Annotation, name: 'dynamic/issuer', value: issuer_id),
            instance_double(Annotation, name: 'other-annotation', value: 'rspec')
          ]
        end

        context 'when the issuer does not exist' do
          it 'returns an error' do
            view_secret
            expect(response.code).to eq("422")
            expect(response.body).to include('Issuer assigned to rspec:variable:data/dynamic/test was not found')
          end
        end

        context 'when the issuer exists' do
          let(:issuer_secret_value) { 'placeholder_value' }
          let(:issuer_double) do
            instance_double(
              Issuer,
              issuer_type: 'placeholder',
              max_ttl: 10,
              data: '{"value": "test"}'
            ).tap do |issuer_double|
            end
          end

          before do
            allow(Issuer)
              .to receive(:first)
              .with(account: account, issuer_id: issuer_id)
              .and_return(issuer_double)

            stub_request(:post, "http://dynamic-secrets:8080/secrets")
              .with(
                body: "{\"type\":\"placeholder\",\"method\":null,\"role\":\"rspec:user:admin\",\"issuer\":{\"max_ttl\":10,\"data\":{\"value\":\"test\"}},\"secret\":{\"issuer\":\"my-placeholder-issuer\"}}"
              )
              .to_return(status: 200, body: issuer_secret_value, headers: {})
          end

          it 'returns the secret' do
            view_secret
            expect(response.body).to eq(issuer_secret_value)
          end

          context 'when the ephemeral secrets engine is not configured' do
            before do
              allow(Rails.application.config)
                .to receive(:try)
                .with(:ephemeral_secrets_service_address)
                .and_return(nil)

              allow(Rails.application.config)
                .to receive(:try)
                .with(:ephemeral_secrets_service_port)
                .and_return(nil)
            end

            it 'returns an error' do
              view_secret
              expect(response.code).to eq("422")
              expect(response.body)
                .to include('No ephemeral secret engine configured for Conjur')
            end
          end
        end
      end

      context 'when dynamic secrets are not enabled' do
        let(:dynamic_secrets_enabled) { false }

        it 'is treated like a regular secret' do
          view_secret
          expect(response.code).to eq("200")
          expect(response.body).to eq(secret_value)
        end
      end
    end
  end
end

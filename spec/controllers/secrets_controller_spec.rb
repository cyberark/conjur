# frozen_string_literal: true

require 'spec_helper'
require 'parallel'

DatabaseCleaner.strategy = :truncation

describe SecretsController, type: :request do
  let(:test_policy) do
    <<~POLICY
      - !variable
        id: test
    POLICY
  end

  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:policy_url) do
    '/policies/rspec/policy/root'
  end
  let(:secret_url) do
    '/secrets/rspec/variable/test'
  end
  let(:secret) { "test" }
  let(:role_actual) { Role.find_or_create(role_id: role_resource_id) }

  let(:secret_url) { '/secrets/rspec/variable/test' }
  let(:secret_value) { "test" }
  let(:secret_mime_type) { nil }

  let(:read_permitted) { true }
  let(:update_permitted) { true }
  let(:execute_permitted) { true }

  let(:secret_resource_id) { 'rspec:variable:test' }
  let(:role_resource_id) { 'rspec:user:admin' }

  let(:role_double) do
    instance_double(
      Role,
      id: role_resource_id
    )
  end

  let(:resource_double) do
    instance_double(
      Resource,
      id: secret_resource_id,
      resource_id: secret_resource_id
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
        .to receive(:pk_hash)
        .and_return({ resource: secret_resource_id })

      allow(resource_double).to receive(:enforce_secrets_version_limit)
    end
  end

  let(:secret_double) do
    instance_double(
      Secret,
      value: secret_value
    )
  end

  def load_secret
    post(
      secret_url,
      env: token_auth_header(role: role_actual).merge(
        { 'RAW_POST_DATA' => secret }
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
    Slosilo['authn:rspec'] ||= Slosilo::Key.new

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
  end

  describe '#create' do
    # Tests that the controller catches an error that will accure when you are
    # making a write request and the psql user does not have the correct
    # permission.
    #
    # This is not specific to this controller.
    context 'when you do not have write privlages to the database'  do
      before do
        allow(Secret)
          .to receive(:create)
          .and_raise(PG::InsufficientPrivilege)
        load_secret
      end

      it 'should return a 405 error' do
        expect(response.code).to eq("405")
        res = JSON.parse(response.body)

        expect(res["error"]["message"])
          .to eq("Write operations are not allowed")
      end
    end

    context 'when the secret is empty' do
      let(:secret) { nil }
      it 'should return an error' do
        load_secret
        expect(response.code).to eq("422")
        res = JSON.parse(response.body)

        expect(res["error"]["message"])
          .to eq("'value' may not be empty")
      end
    end

    it 'should return a 201 status code' do
      load_secret
      expect(response.code).to eq("201")
    end
  end

  describe '#show' do
    # Tests that the controller catches an error that will accure when you are
    # making a read request and the psql user does not have the correct
    # permission.
    #
    # This is not specific to this controller.
    context 'when you do not have Read privlages to the database'  do
      before do
        allow(Resource)
          .to receive(:[])
          .and_raise(PG::InsufficientPrivilege)
        view_secret
      end

      it 'should return a 405 status code' do
        expect(response.code).to eq("405")
        res = JSON.parse(response.body)

        expect(res["error"]["message"])
          .to eq("Read operations are not allowed")
      end
    end

    it 'should return a 200 status code' do
      view_secret
      expect(response.code).to eq("200")
    end

    it 'should return the secret' do
      view_secret
      expect(response.body).to eq(secret)
    end
  end
end

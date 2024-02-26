require 'spec_helper'
require './app/domain/util/static_account'

DatabaseCleaner.strategy = :truncation

describe StaticSecretsController, type: :request do
  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:alice_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
  let(:bob_user) { Role.find_or_create(role_id: 'rspec:user:bob') }

  let(:expected_event_object) { instance_double(Audit::Event::Policy) }
  let(:log_object) { instance_double(::Audit::Log::SyslogAdapter, log: expected_event_object) }

  let(:test_policy) do
    <<~POLICY
      - !user alice
      
      - !policy
        id: data
        body:
        - !variable
          id: mySecret
          mime_type: text/plain 

      - !permit
        role: !user alice
        privileges: [ read ]
        resource: !variable data/mySecret


    POLICY
  end

  before do
    StaticAccount.set_account('rspec')
    allow(Audit).to receive(:logger).and_return(log_object)

    init_slosilo_keys("rspec")
    # Load the test policy into Conjur
    put(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        'RAW_POST_DATA' => test_policy 
      )
    )
    assert_response :success
  end

  describe 'Get existisng variable' do
    context 'when the user has read permission' do
      it 'returns 200' do
        get(
          '/secrets/static/data/mySecret',
          env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :success
        validate_response('mySecret', 'data', 'text/plain')
      end
    end
    context 'when the user does not have read permission' do
      it 'returns 403' do
        get(
          '/secrets/static/data/mySecret',
          env: token_auth_header(role: bob_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :forbidden
      end
    end
  end

  describe 'Get non existisng variable' do
    context 'when the user has read permission' do
      it 'returns 404' do
        get(
          '/secrets/static/data/doesNotExist',
          env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :not_found
      end
    end
    context 'when the user does not have read permission' do
      it 'returns 404' do
        get(
          '/secrets/static/data/doesNotExist',
          env: token_auth_header(role: bob_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :not_found 
      end
    end
  end
  
  describe 'Get variable with invalid branch' do
    context 'when the user has read permission' do
      it 'returns 404' do
        get(
          '/secrets/static/doesNotExist/mySecret',
          env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :not_found
      end
    end
  end

  def validate_response(name, branch, mime_type)
    response_body = JSON.parse(response.body)
    expect(response_body['name']).to eq(name)
    expect(response_body['branch']).to eq(branch)
    expect(response_body['mime_type']).to eq(mime_type)
  end
end

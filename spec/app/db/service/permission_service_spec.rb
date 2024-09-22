# frozen_string_literal: true

require 'spec_helper'

describe DB::Service::PermissionService do
  subject { described_class.instance }

  context 'Create Group Permission' do
    role_id =  'rspec:group:internal/system:config'
    policy_id =  'rspec:policy:my_policy'
    privilege ='read'
    resource_id ='rspec:variable:branch1/branch2/my_secret'

    before do
      Role.create(role_id: role_id)
      Resource.create(resource_id: resource_id, owner_id: role_id)
      Resource.create(resource_id: policy_id, owner_id: role_id)
    end

    it 'create permission successfully' do
      subject.create_permission(resource_id, privilege, role_id, policy_id)

      db_object = ::Permission[resource_id: resource_id]
      expect(db_object[:resource_id]).to eq(resource_id)
      expect(db_object[:privilege]).to eq(privilege)
      expect(db_object[:role_id]).to eq(role_id)
      expect(db_object[:policy_id]).to eq(policy_id)
    end

    it 'sends event' do
      allow(Rails.application.config.conjur_config).to receive(:conjur_pubsub_enabled).and_return(true)
      subject.create_permission(resource_id, privilege, role_id, policy_id)
      events = Event.all

      expect(events.size).to eq(1)
      event = events[0]

      expected_params = { event_type: 'conjur.secret.permission.created',
                          branch: 'branch1/branch2',
                          name: 'my_secret',
                          privilege: 'read',
                          id: 'internal/system:config',
                          kind: 'group' }

      verify_permission_event(event, expected_params)
    end
  end

  context 'Create Host Permission' do
    role_id =  'rspec:host:internal/system:config'
    policy_id =  'rspec:policy:my_policy'
    privilege ='read'
    resource_id ='rspec:variable:my_secret'

    before do
      Role.create(role_id: role_id)
      Resource.create(resource_id: resource_id, owner_id: role_id)
      Resource.create(resource_id: policy_id, owner_id: role_id)
    end

    it 'create permission successfully' do
      subject.create_permission(resource_id, privilege, role_id, policy_id)

      db_object = ::Permission[resource_id: resource_id]
      expect(db_object[:resource_id]).to eq(resource_id)
      expect(db_object[:privilege]).to eq(privilege)
      expect(db_object[:role_id]).to eq(role_id)
      expect(db_object[:policy_id]).to eq(policy_id)
    end

    it 'sends event' do
      allow(Rails.application.config.conjur_config).to receive(:conjur_pubsub_enabled).and_return(true)
      subject.create_permission(resource_id, privilege, role_id, policy_id)
      events = Event.all

      expect(events.size).to eq(1)
      event = events[0]

      expected_params = { event_type: 'conjur.secret.permission.created',
                          branch: 'root',
                          name: 'my_secret',
                          privilege: 'read',
                          id: 'internal/system:config',
                          kind: 'workload' }

      verify_permission_event(event, expected_params)
    end
  end

  context 'Create User Permission' do
    role_id =  'rspec:user:my_admin'
    policy_id =  'rspec:policy:my_policy'
    privilege ='read'
    resource_id ='rspec:variable:my_secret'

    before do
      Role.create(role_id: role_id)
      Resource.create(resource_id: resource_id, owner_id: role_id)
      Resource.create(resource_id: policy_id, owner_id: role_id)
    end

    it 'create permission successfully' do
      subject.create_permission(resource_id, privilege, role_id, policy_id)

      db_object = ::Permission[resource_id: resource_id]
      expect(db_object[:resource_id]).to eq(resource_id)
      expect(db_object[:privilege]).to eq(privilege)
      expect(db_object[:role_id]).to eq(role_id)
      expect(db_object[:policy_id]).to eq(policy_id)
    end

    it 'sends event' do
      allow(Rails.application.config.conjur_config).to receive(:conjur_pubsub_enabled).and_return(true)
      subject.create_permission(resource_id, privilege, role_id, policy_id)
      events = Event.all

      expect(events.size).to eq(1)
      event = events[0]

      expected_params = { event_type: 'conjur.secret.permission.created',
                          branch: 'root',
                          name: 'my_secret',
                          privilege: 'read',
                          id: 'my_admin',
                          kind: 'user' }

      verify_permission_event(event, expected_params)
    end
  end

  context 'Delete User Permission' do
    role_id =  'rspec:user:my_admin'
    policy_id =  'rspec:policy:my_policy'
    privilege ='read'
    resource_id ='rspec:variable:my_secret'
    non_existing_resource_id ='rspec:variable:no_in_db'

    before do
      Role.create(role_id: role_id)
      Resource.create(resource_id: resource_id, owner_id: role_id)
      Resource.create(resource_id: policy_id, owner_id: role_id)
      subject.create_permission(resource_id, privilege, role_id, policy_id)
    end

    it 'delete permission successfully when all fields are provided' do
      subject.delete_permission(resource_id, privilege, role_id, policy_id)

      db_object = ::Permission[resource_id: resource_id]
      expect(db_object).to be_nil
    end

    it 'does nothing if the permission is nil' do
      subject.delete_permission(nil, privilege, role_id, policy_id)

      db_object = ::Permission[resource_id: resource_id]
      expect(db_object).not_to be_nil 
    end

    it 'does nothing if the resource does not exists' do
      subject.delete_permission(non_existing_resource_id, privilege, role_id, policy_id)

      db_object = ::Permission[resource_id: resource_id]
      expect(db_object).not_to be_nil 
    end

    it 'sends event' do
      allow(Rails.application.config.conjur_config).to receive(:conjur_pubsub_enabled).and_return(true)
      subject.delete_permission(resource_id, privilege, role_id, policy_id)
      events = Event.all

      expect(events.size).to eq(1)
      event = events[0]

      expected_params = { event_type: 'conjur.secret.permission.deleted',
                          branch: 'root',
                          name: 'my_secret',
                          privilege: 'read',
                          id: 'my_admin',
                          kind: 'user' }

      verify_permission_event(event, expected_params)
    end
  end

  def verify_permission_event(event, expected_params) 
    event_value = JSON.parse(event.event_value) 
    expect(event_value['specversion']).to eq('1.0')
    expect(event.event_type).to eq(expected_params[:event_type])

    response_data = event_value['data']
    response_permission = event_value['data']['permission']
    response_subject = event_value['data']['permission']['subject']

    expect(response_data['branch']).to eq(expected_params[:branch])
    expect(response_data['name']).to eq(expected_params[:name])
    expect(response_permission['privilege']).to eq(expected_params[:privilege])
    expect(response_subject['id']).to eq(expected_params[:id])
    expect(response_subject['kind']).to eq(expected_params[:kind])
  end
end

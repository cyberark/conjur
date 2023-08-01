# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

RSpec.describe(Policy::LoadPolicy) do
  def role(kind:, id:)
    double('Role').tap do |role|
      allow(role).to receive(:kind).and_return(kind)
      allow(role).to receive(:id).and_return(id)
    end
  end

  let(:loader_class) { double(Loader::ModifyPolicy) }
  let(:audit_logger) { double(::Audit.logger) }
  let(:logger) { double(Rails.logger) }

  let(:delete_permitted) { false }
  let(:action) { :update }
  let(:resource) { double('Resource') }
  let(:policy_text) { "test policy text" }
  let(:current_user) { double('User') }
  let(:client_ip) { '127.0.0.1' }

  let(:saved_policy) { instance_double(PolicyVersion) }
  let(:loaded_policy) { instance_double(Loader::ModifyPolicy) }
  let(:created_roles) do
    {
      role1: {
        id: "org:user:role1",
        api_key: "2173r81q337vjhkcqtg3tsdpbs3bbb2qv1d8rzqc3kvaf6j27zweqm"
      },
      role2: {
        id: "org:user:role2",
        api_key: "2173r81q437vjhkcqtg3tsdpbs3bbb2qv1d8rzqc3kvaf6j27zweqm"
      }
    }
  end

  let(:new_roles) {
    [
      role(kind: 'host', id: 'role1'),
      role(kind: 'user', id: 'role2'),
      role(kind: 'something-else', id: 'not_an_actor')
    ]
  }
  let(:new_actor_roles) {
    [
      role(kind: 'host', id: 'role1'),
      role(kind: 'user', id: 'role2'),
    ]
  }

  subject do
    Policy::LoadPolicy.new(
      loader_class: loader_class,
      audit_logger: audit_logger,
      logger: logger
    )
  end

  describe ".call" do
    def load_policy
      subject.(
        delete_permitted: delete_permitted,
        action: action,
        resource: resource,
        policy_text: policy_text,
        current_user: current_user,
        client_ip: client_ip
      )
    end

    context "with an authorized user" do
      it "loads the policy" do
        expect(subject).to receive(:auth).with(current_user, action, resource)     
        expect(subject).to receive(:save_submitted_policy).with(
          delete_permitted: delete_permitted,
          current_user: current_user,
          policy_text: policy_text,
          resource: resource,
          client_ip: client_ip
        ).and_return(saved_policy)

        expect(loader_class).to receive(:from_policy).with(saved_policy).and_return(loaded_policy)
        expect(subject).to receive(:perform).with(loaded_policy).and_return(created_roles)
        expect(subject).to receive(:audit_success).with(saved_policy)
        expect(load_policy).to eq({created_roles: created_roles, policy: saved_policy})
      end
    end

    context "with an unauthorized user" do
      it "fails to load the policy" do
        expect(subject).to receive(:auth).with(any_args).and_raise(ArgumentError)
        expect(subject).to receive(:audit_failure).with(anything, action, current_user, client_ip)
        expect{ load_policy }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".audit_success" do
    let(:event1) { instance_double(Audit::Event::Policy) }
    let(:event2) { instance_double(Audit::Event::Policy) }

    def policy_log(event)
      double(PolicyLog).tap do |log|
        allow(log).to receive(:to_audit_event).and_return(event)
      end
    end
    let(:policy_logs) { [policy_log(event1), policy_log(event2)] }
    
    it "logs each of the policy events" do
      expect(saved_policy).to receive(:policy_log).and_return(policy_logs)
      expect(audit_logger).to receive(:log).with(event1)
      expect(audit_logger).to receive(:log).with(event2)
      subject.audit_success(saved_policy)
    end
  end

  describe ".audit_failure" do
    let(:error_message) { "some error details" }
    let(:error) { instance_double(ArgumentError).tap do |error|
        allow(error).to receive(:message).and_return(error_message)
      end
    }
    let(:audit_event) { instance_double(Audit::Event::Policy) }

    it "logs a new policy event" do
      expect(Audit::Event::Policy).to receive(:new).with(
          operation: action,
          subject: {},
          user: current_user,
          client_ip: client_ip,
          error_message: error_message
      ).and_return(audit_event)
      expect(audit_logger).to receive(:log).with(audit_event)
      subject.audit_failure(error, action, current_user, client_ip)
    end
  end

  describe ".save_submitted_policy" do
    def save_policy
      subject.save_submitted_policy(
        delete_permitted: delete_permitted,
        current_user: current_user,
        policy_text: policy_text,
        resource: resource,
        client_ip: client_ip
      )
    end

    context "with valid parameters" do
      it "creates and saves a PolicyVersion" do
        expect(PolicyVersion).to receive(:new).with(
          role: current_user,
          policy: resource,
          policy_text: policy_text,
          client_ip: client_ip
        ).and_return(saved_policy)

        expect(saved_policy).to receive("delete_permitted=").with(delete_permitted)
        expect(saved_policy).to receive(:save).and_return(saved_policy)
        expect(save_policy).to eq(saved_policy)
      end
    end
  end

  describe ".perform" do
    let(:policy_action) { instance_double(Loader::ModifyPolicy) }

    context "with a valid policy action" do
      it "performs the action and creates roles" do
        expect(policy_action).to receive(:call)
        expect(policy_action).to receive(:new_roles).and_return(new_roles)
        expect(subject).to receive(:actor_roles).with(new_roles).and_return(new_actor_roles)
        expect(subject).to receive(:create_roles).with(new_actor_roles).and_return(created_roles)
        expect(subject.perform(policy_action)).to eq(created_roles)
      end
    end
  end

  describe ".actor_roles" do
    context "with user/host and other roles" do
      it "returns only the user/host roles" do
        roles = new_actor_roles + [role(kind: 'something-else', id: 'not_an_actor')]
        expect(subject.actor_roles(roles)).to eq(new_actor_roles)
      end
    end
    
    context "with only user/host roles" do
      it "returns the passed array" do
        expect(subject.actor_roles(new_actor_roles)).to eq(new_actor_roles)
      end
    end

    context "with only non-user/host roles" do
      let(:non_actor_roles) {
        [
          role(kind: 'something-else', id: 'not_an_actor'),
          role(kind: 'something-else-entirely', id: 'not_an_actor2')
        ]
      }

      it "returns an empty array" do
        expect(subject.actor_roles(non_actor_roles)).to eq([])
      end
    end

    context "with no roles" do
      it "returns the empty array" do
        expect(subject.actor_roles([])).to eq([])
      end
    end
  end

  describe ".create_roles" do
    def credential
      instance_double(Credentials).tap do |cred|
        allow(cred).to receive(:api_key).and_return(SecureRandom.hex(54))
      end
    end

    let(:role1) { role(kind: 'host', id: 'role1') }
    let(:role2) { role(kind: 'user', id: 'role2') }

    let(:role1_credential){ credential }
    let(:role2_credential){ credential }

    let(:actor_roles) { [ role1, role2 ] }

    context "when all roles have existing credentials" do
      it "loads the existing credentials" do
        expect(Credentials).to receive(:[]).with(role: role1).and_return(role1_credential)
        expect(Credentials).to receive(:[]).with(role: role2).and_return(role2_credential)

        expect(subject.create_roles(actor_roles)).to eq({
          role1.id => { id: role1.id, api_key: role1_credential.api_key },
          role2.id => { id: role2.id, api_key: role2_credential.api_key }
        })
      end
    end

    context "when roles don't have existing credentials" do
      it "creates new credentials" do
        expect(Credentials).to receive(:[]).with(role: role1).and_return(nil)
        expect(Credentials).to receive(:create).with(role: role1).and_return(role1_credential)

        expect(Credentials).to receive(:[]).with(role: role2).and_return(nil)
        expect(Credentials).to receive(:create).with(role: role2).and_return(role2_credential)

        expect(subject.create_roles(actor_roles)).to eq({
          role1.id => { id: role1.id, api_key: role1_credential.api_key },
          role2.id => { id: role2.id, api_key: role2_credential.api_key }
        })
      end
    end

    context "when some roles have credentials and some don't" do
      it "prefers loading existing credentials" do
        expect(Credentials).to receive(:[]).with(role: role1).and_return(role1_credential)

        expect(Credentials).to receive(:[]).with(role: role2).and_return(nil)
        expect(Credentials).to receive(:create).with(role: role2).and_return(role2_credential)

        expect(subject.create_roles(actor_roles)).to eq({
          role1.id => { id: role1.id, api_key: role1_credential.api_key },
          role2.id => { id: role2.id, api_key: role2_credential.api_key }
        })
      end
    end

    context "with no roles" do
      it "doesn't load any credentials" do
        expect(Credentials).not_to receive(:create)
        expect(subject.create_roles([])).to eq({})
      end
    end
  end
end

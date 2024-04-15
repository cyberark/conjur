require 'spec_helper'

describe Loader::Types::User do
  let(:user) do
    role = Conjur::PolicyParser::Types::Role.new
    role.id = role_id
    role.kind = role_kind
    role.account = 'default'
    user = Conjur::PolicyParser::Types::User.new
    user.id = resource_id
    user.account = 'default'
    user.owner = role
    Loader::Types.wrap(user, self)
  end

  describe '.verify' do
    context 'when CONJUR_USERS_IN_ROOT_POLICY_ONLY is true' do
      before do
        allow(ENV).to receive(:[]).with('CONJUR_USERS_IN_ROOT_POLICY_ONLY').and_return('true')
      end

      context 'when creating user in the "admin" sub-policy' do
        let(:resource_id) { 'alice@admin' }
        let(:role_kind) { 'policy' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to raise_error(Exceptions::InvalidPolicyObject) }
      end

      context 'when non admin user creating user in the "root" policy' do
        let(:resource_id) { 'alice@cyberark' }
        let(:role_kind) { 'user' }
        let(:role_id) { 'myuser' }
        it { expect { user.verify }.to raise_error(Exceptions::InvalidPolicyObject) }
      end

      context 'when admin user creating user in the "root" policy' do
        let(:resource_id) { 'alice@cyberark' }
        let(:role_kind) { 'user' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to_not raise_error }
      end
    end

    context 'when CONJUR_USERS_IN_ROOT_POLICY_ONLY is false' do
      before do
        allow(ENV).to receive(:[]).with('CONJUR_USERS_IN_ROOT_POLICY_ONLY').and_return('false')
      end

      context 'when creating user in the "admin" sub-policy' do
        let(:resource_id) { 'alice@admin' }
        let(:role_kind) { 'policy' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to_not raise_error }
      end

      context 'when non admin user creating user in the "root" policy' do
        let(:role_kind) { 'user' }
        let(:resource_id) { 'alice@cyberark' }
        let(:role_id) { 'myuser' }
        it { expect { user.verify }.to_not raise_error }
      end

      context 'when admin user creating user in the "root" policy' do
        let(:role_kind) { 'user' }
        let(:resource_id) { 'alice@cyberark' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to_not raise_error }
      end
    end

    context 'when CONJUR_USERS_IN_ROOT_POLICY_ONLY is not set' do
      context 'when creating user in the "admin" sub-policy' do
        let(:resource_id) { 'alice@admin' }
        let(:role_kind) { 'policy' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to_not raise_error }
      end

      context 'when admin user creating user in the "root" policy' do
        let(:resource_id) { 'alice@cyberark' }
        let(:role_kind) { 'user' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to_not raise_error }
      end
    end
  end
end

describe Loader::Types::Variable do
  let(:variable) do
    variable = Conjur::PolicyParser::Types::Variable.new
    variable.id = resource_id
    variable.account = "conjur"
    variable.annotations =  {}
    if issuer_id != ''
      variable.annotations = variable.annotations.merge({ "dynamic/issuer" => issuer_id })
    end
    if method != ''
      variable.annotations = variable.annotations.merge({ "dynamic/method" => method })
    end
    if ttl != ''
      variable.annotations =  variable.annotations.merge({ "dynamic/ttl" => ttl })
    end
    Loader::Types.wrap(variable, self)
  end

  describe '.verify' do
    context 'when no issuer configured' do
      before do
        $primary_schema = "public"
      end

      context 'when creating regular variable without dynamic/issuer annotation' do
        let(:resource_id) { 'data/myvar1' }
        let(:issuer_id) { '' }
        let(:method) { '' }
        let(:ttl) { '' }
        it { expect { variable.verify }.to_not raise_error }
      end

      context 'when creating regular variable with dynamic/issuer annotation' do
        let(:resource_id) { 'data/myvar2' }
        let(:issuer_id) { 'aws1' }
        it { expect { variable.verify }.to raise_error }
      end

      context 'when creating dynamic variable without dynamic/issuer annotation' do
        let(:resource_id) { 'data/dynamic/myvar1' }
        let(:issuer_id) { '' }
        it { expect { variable.verify }.to raise_error }
      end

      context 'when creating dynamic variable with dynamic/issuer annotation' do
        let(:resource_id) { 'data/dynamic/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:method) { 'federation-token' }
        let(:ttl) { 900 }
        it { expect { variable.verify }.to raise_error(Exceptions::RecordNotFound,"Issuer 'aws1' not found in account 'conjur'" ) }
      end
    end

    context 'when issuer aws1 configured without permissions' do
      before do
        allow(Issuer).to receive(:where).with({:account=>"conjur", :issuer_id=>"aws1"}).and_return(issuer_object)
        $primary_schema = "public"
      end

      context 'when creating regular variable with dynamic/issuer annotation' do
        let(:resource_id) { 'data/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:method) { 'federation-token' }
        let(:ttl) { 900 }
        let(:issuer_object) { nil }
        it "raise not InvalidPolicyObject" do
          allow(Issuer).to receive(:where).with({:account=>"conjur", :issuer_id=>"aws1"}).and_return(issuer_object)
          expect { variable.verify }.to raise_error(Exceptions::InvalidPolicyObject,"The dynamic variable 'data/myvar2' is not in the correct path")
        end
      end

      context 'when creating dynamic variable with dynamic/issuer annotation' do
        let(:resource_id) { 'data/dynamic/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:method) { 'federation-token' }
        let(:ttl) { 900 }
        let(:issuer_object) { nil }
        it "raise not InvalidPolicyObject" do
          allow(Issuer).to receive(:where).with({:account=>"conjur", :issuer_id=>"aws1"}).and_return(issuer_object)
          allow(issuer_object).to receive(:first).and_return(nil)
          expect { variable.verify }.to raise_error(Exceptions::RecordNotFound,"Issuer 'aws1' not found in account 'conjur'")
        end
      end

      context 'when creating dynamic variable with dynamic/issuer annotation' do
        let(:resource_id) { 'data/dynamic/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:method) { 'federation-token' }
        let(:ttl) { 900 }
        let(:issuer_object) { 'issuer' }
        it "raise not InvalidPolicyObject" do
          allow(issuer_object).to receive(:first).and_return({ :issuer_type => "aws", :max_ttl => 2000 })
          allow_any_instance_of(Loader::Types::Record).to receive(:auth_resource).and_raise(Exceptions::RecordNotFound,"rspec:issuer:aws1")
          expect { variable.verify }.to raise_error(Exceptions::RecordNotFound,"Issuer 'aws1' not found in account 'rspec'")
        end
      end
    end

    context 'when issuer aws1 configured with permissions' do
      before do
        allow(issuer_object).to receive(:first).and_return({ :issuer_type => "aws", :max_ttl => 2000 })
        allow(Issuer).to receive(:where).with({:account=>"conjur", :issuer_id=>"aws1"})
          .and_return(issuer_object)
        allow_any_instance_of(AuthorizeResource).to receive(:authorize).with(:use, nil)
        $primary_schema = "public"
      end

      context 'when creating regular variable with dynamic/issuer aws1' do
        let(:resource_id) { 'data/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:method) { 'federation-token' }
        let(:ttl) { 900 }
        let(:issuer_object) { 'issuer'  }
        it "raise not InvalidPolicyObject" do
          expect { variable.verify }.to raise_error(Exceptions::InvalidPolicyObject,"The dynamic variable 'data/myvar2' is not in the correct path")
        end
      end

      context 'when creating dynamic variable with dynamic/issuer aws1' do
        let(:resource_id) { 'data/dynamic/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:method) { 'federation-token' }
        let(:ttl) { 900 }
        let(:issuer_object) { 'issuer'  }
        it "raise not found record error" do
          allow_any_instance_of(Loader::Types::Record).to receive(:auth_resource).and_raise(Exceptions::RecordNotFound,"rspec:issuer:aws1")
          expect { variable.verify }.to raise_error(Exceptions::RecordNotFound,"Issuer 'aws1' not found in account 'rspec'")
        end
      end

      context 'when creating dynamic variable with dynamic/issuer aws1 and with permissions' do
        let(:resource_id) { 'data/dynamic/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:method) { 'federation-token' }
        let(:ttl) { 900 }
        let(:issuer_object) { 'issuer' }
        it "should not raise error" do
          allow_any_instance_of(Loader::Types::Record).to receive(:auth_resource)
          expect { variable.verify }.not_to raise_error
        end
      end
      context 'when issuer aws1 configured without method' do
        let(:resource_id) { 'data/dynamic/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:method) { '' } # empty on purpose
        let(:ttl) { 900 }
        let(:issuer_object) { 'issuer'  }
        it "raise not found record error" do
          expect { variable.verify }.to raise_error(Exceptions::InvalidPolicyObject, "The dynamic variable 'data/dynamic/myvar2' has no method annotation")
        end
      end
      context 'when issuer aws1 configured with wrong ttl for federation' do
        let(:resource_id) { 'data/dynamic/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:method) { 'federation-token' } 
        let(:ttl) { 899 }
        let(:issuer_object) { 'issuer'  }
        it "raise not found record error" do
          allow(issuer_object).to receive(:first).and_return({ :issuer_type => "aws", :max_ttl => 2000 })
          expect { variable.verify }.to raise_error(Exceptions::InvalidPolicyObject, "Dynamic variable TTL is out of range for federation token (range is 900 to 43200)")
        end
        it "raise not found record error" do
          allow(issuer_object).to receive(:first).and_return({ :issuer_type => "aws", :max_ttl => 2000 })
          variable.annotations["dynamic/ttl"] = 43201
          expect { variable.verify }.to raise_error(Exceptions::InvalidPolicyObject, "Dynamic variable TTL is out of range for federation token (range is 900 to 43200)")
        end
      end
      context 'when issuer aws1 configured with wrong ttl for assume role' do
        let(:resource_id) { 'data/dynamic/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:method) { 'assume-role' } 
        let(:ttl) { 899 }
        let(:issuer_object) { 'issuer'  }
        it "raise not found record error" do
          allow(issuer_object).to receive(:first).and_return({ :issuer_type => "aws", :max_ttl => 2000 })
          expect { variable.verify }.to raise_error(Exceptions::InvalidPolicyObject, "Dynamic variable TTL is out of range for assume role (range is 900 to 129600)")
        end
        it "raise not found record error" do
          allow(issuer_object).to receive(:first).and_return({ :issuer_type => "aws", :max_ttl => 2000 })
          variable.annotations["dynamic/ttl"] = 129601
          expect { variable.verify }.to raise_error(Exceptions::InvalidPolicyObject, "Dynamic variable TTL is out of range for assume role (range is 900 to 129600)")
        end
      end
    end
  end

  describe Loader::Types::Delete do
    context "Delete from Redis" do

      let(:account) { "rspec" }
      let(:data_var_id) { "#{account}:variable:data/conjur_secret" }
      let(:my_host) { "#{account}:host:data/my-host" }
      let(:user_owner_id) { 'rspec:user:admin' }
      let(:policy_record) { double(PolicyVersion) }
      let(:record) { double("record") }

      before do
        Role.find_or_create(role_id: user_owner_id)
        allow(policy_record).to receive(:record).and_return(record)
      end

      subject { described_class.new(policy_record) }

      it "Variable is deleted from Redis on !delete" do
        Resource.create(resource_id: data_var_id, owner_id: user_owner_id)
        allow(record).to receive(:resourceid).and_return(data_var_id)
        expect(Rails.cache).to receive(:delete).with(data_var_id)
        subject.delete!
      end

      it "Non variable resource does not invoke redis" do
        Resource.create(resource_id: my_host, owner_id: user_owner_id)
        Role.find_or_create(role_id: my_host)
        allow(record).to receive(:resourceid).and_return(my_host)
        expect(Rails.cache).to_not receive(:delete)
        subject.delete!
      end

      it "Variable that doesn't exist in Resource table" do
        allow(record).to receive(:resourceid).and_return(data_var_id)
        expect(Rails.cache).to_not receive(:delete).with(data_var_id)
        expect{ subject.delete! }.to_not raise_error
      end
    end
  end
end

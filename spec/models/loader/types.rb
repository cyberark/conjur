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

describe Loader::Types::Host do
  let(:host) do
    host = Conjur::PolicyParser::Types::Host.new
    host.id = resource_id
    if api_key != ''
      host.annotations =  { "authn/api-key" => api_key }
    end
    Loader::Types.wrap(host, self)
  end

  describe '.verify' do
    context 'when CONJUR_AUTHN_API_KEY_DEFAULT is true' do
      before do
        allow(Rails.application.config.conjur_config).to receive(:authn_api_key_default).and_return(true)
      end

      context 'when creating host with api-key annotation true' do
        let(:resource_id) { 'myhost@admin' }
        let(:api_key) { true }
        it { expect { host.verify }.to_not raise_error }
      end

      context 'when creating host with api-key annotation false' do
        let(:resource_id) { 'myhost@cyberark' }
        let(:api_key) { false }
        it { expect { host.verify }.to_not raise_error(Exceptions::InvalidPolicyObject) }
      end

      context 'when creating host without api-key annotation' do
        let(:resource_id) { 'myhost@cyberark' }
        let(:api_key) { '' }
        it { expect { host.verify }.to_not raise_error(Exceptions::InvalidPolicyObject) }
      end
    end

    context 'when CONJUR_AUTHN_API_KEY_DEFAULT is false' do
      before do
        allow(Rails.application.config.conjur_config).to receive(:authn_api_key_default).and_return(false)
      end

      context 'when creating host with api-key annotation true' do
        let(:resource_id) { 'myhost@admin' }
        let(:api_key) { true }
        it { expect { host.verify }.to_not raise_error }
      end

      context 'when creating host with api-key annotation false' do
        let(:resource_id) { 'alice@cyberark' }
        let(:api_key) { false }
        it { expect { host.verify }.to raise_error }
      end

      context 'when creating host without api-key annotation' do
        let(:resource_id) { 'alice@cyberark' }
        let(:api_key) { '' }
        it { expect { host.verify }.to raise_error }
      end
    end

  end
end

describe Loader::Types::Variable do
  let(:variable) do
    variable = Conjur::PolicyParser::Types::Variable.new
    variable.id = resource_id
    variable.account = "conjur"
    if issuer_id != ''
      variable.annotations =  { "ephemeral/issuer" => issuer_id }
    end
    Loader::Types.wrap(variable, self)
  end

  describe '.verify' do
    context 'when no issuer configured' do
      before do
        $primary_schema = "public"
      end

      context 'when creating regular variable without ephemerals/issuer annotation' do
        let(:resource_id) { 'data/myvar1' }
        let(:issuer_id) { '' }
        it { expect { variable.verify }.to_not raise_error }
      end

      context 'when creating regular variable with ephemerals/issuer annotation' do
        let(:resource_id) { 'data/myvar2' }
        let(:issuer_id) { 'aws1' }
        it { expect { variable.verify }.to raise_error }
      end

      context 'when creating ephemeral variable without ephemerals/issuer annotation' do
        let(:resource_id) { 'data/ephemerals/myvar1' }
        let(:issuer_id) { '' }
        it { expect { variable.verify }.to raise_error }
      end

      context 'when creating ephemeral variable with ephemerals/issuer annotation' do
        let(:resource_id) { 'data/ephemerals/myvar2' }
        let(:issuer_id) { 'aws1' }
        it { expect { variable.verify }.to raise_error }
      end
    end

    context 'when issuer aws1 configured without permissions' do
      before do
        allow(Issuer).to receive(:where).with({:account=>"conjur", :issuer_id=>"aws1"}).and_return(issuer_object)
        $primary_schema = "public"
      end

      context 'when creating regular variable with ephemerals/issuer annotation' do
        let(:resource_id) { 'data/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:issuer_object) { nil }
        it { expect { variable.verify }.to raise_error }
      end

      context 'when creating ephemeral variable with ephemerals/issuer annotation' do
        let(:resource_id) { 'data/ephemerals/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:issuer_object) { nil }
        it { expect { variable.verify }.to raise_error }
      end

      context 'when creating ephemeral variable with ephemerals/issuer annotation' do
        let(:resource_id) { 'data/ephemerals/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:issuer_object) { 'issuer' }
        it { expect { variable.verify }.to raise_error }
      end
    end

    context 'when issuer aws1 configured with permissions' do
      before do
        allow(Issuer).to receive(:where).with({:account=>"conjur", :issuer_id=>"aws1"})
          .and_return(issuer_object)
        allow_any_instance_of(AuthorizeResource).to receive(:authorize).with(:use, nil)
        $primary_schema = "public"
      end

      context 'when creating regular variable with ephemerals/issuer aws1' do
        let(:resource_id) { 'data/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:issuer_object) { nil }
        it { expect { variable.verify }.to raise_error }
      end

      context 'when creating ephemeral variable with ephemerals/issuer aws1' do
        let(:resource_id) { 'data/ephemerals/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:issuer_object) { nil }
        it { expect { variable.verify }.to raise_error }
      end

      context 'when creating ephemeral variable with ephemerals/issuer aws1 and with permissions' do
        let(:resource_id) { 'data/ephemerals/myvar2' }
        let(:issuer_id) { 'aws1' }
        let(:issuer_object) { 'issuer' }
        let(:policy_resource) { 'conjur:policy:conjur/issuers/aws1' }
        it { expect { variable.verify }.not_to raise_error }
      end
    end

  end
end

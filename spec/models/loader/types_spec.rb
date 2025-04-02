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
        it { expect { host.verify }.to_not raise_error }
      end

      context 'when creating host without api-key annotation' do
        let(:resource_id) { 'myhost@cyberark' }
        let(:api_key) { '' }
        it { expect { host.verify }.to_not raise_error }
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
        it { expect { host.verify }.to raise_error(Exceptions::InvalidPolicyObject) }
      end

      context 'when creating host without api-key annotation' do
        let(:resource_id) { 'alice@cyberark' }
        let(:api_key) { '' }
        it { expect { host.verify }.to raise_error(Exceptions::InvalidPolicyObject) }
      end
    end
  end
end

describe Loader::Types::Variable do
  let(:variable) do
    Loader::Types::Variable.new(
      variable_policy_object,
      feature_flags: feature_flags_double
    )
  end

  let(:variable_policy_object) do
    Conjur::PolicyParser::Types::Variable.new.tap do |variable|
      variable.id = resource_id
      variable.account = account
      variable.annotations = annotations
    end
  end

  let(:feature_flags_double) do
    instance_double(Conjur::FeatureFlags::Features)
      .tap do |feature_flags_double|
        allow(feature_flags_double)
          .to receive(:enabled?)
          .with(:dynamic_secrets)
          .and_return(dynamic_secrets_enabled)
      end
  end

  let(:dynamic_secrets_enabled) { true }

  describe '#verify' do
    let(:issuer_id) { 'myissuer' }
    let(:account) { 'rspec' }
    let(:issuer_type) { 'aws' }
    let(:method) { 'assume-role' }

    let(:issuer_dataset_double) do
      double("issuers dataset", first: issuer_double)
    end

    let(:issuer_double) do
      instance_double(
        Issuer,
        issuer_type: issuer_type
      )
    end

    let(:token_user_double) do
      double('token user', roleid: current_user_id)
    end

    let(:current_user_id) { 'rspec' }
    let(:current_user_double) do
      instance_double(Role).tap do |role_double|
        allow(role_double)
          .to receive(:allowed_to?)
          .with(:use, issuer_policy_double)
          .and_return(current_user_allowed_to_use_issuer)
      end
    end

    let(:current_user_allowed_to_use_issuer) { true }

    let(:issuer_policy_id) { "#{account}:policy:conjur/issuers/#{issuer_id}" }
    let(:issuer_policy_double) { instance_double(Resource) }

    before do
      allow(Issuer).to receive(:where).with(
        account: account,
        issuer_id: issuer_id
      ).and_return(issuer_dataset_double)

      allow(Conjur::Rack).to receive(:user).and_return(token_user_double)

      allow(Role)
        .to receive(:[])
        .with(current_user_id)
        .and_return(current_user_double)

      allow(Resource)
        .to receive(:[])
        .with(issuer_policy_id)
        .and_return(issuer_policy_double)
    end

    context 'when variable is a dynamic variable' do
      let(:resource_id) { "#{Issuer::DYNAMIC_VARIABLE_PREFIX}myvariable" }

      context 'when issuer annotation is missing' do
        let(:annotations) { {} }
        it 'raises an error' do
          expect { variable.verify }.to raise_error(Exceptions::InvalidPolicyObject)
        end

        context 'when dynamic secrets is not enabled' do
          let(:dynamic_secrets_enabled) { false }

          it 'verifies successfully' do
            expect { variable.verify }.not_to raise_error
          end
        end
      end

      context 'when issuer annotation is present' do
        let(:annotations) { { "#{Issuer::DYNAMIC_ANNOTATION_PREFIX}issuer" => issuer_id } }

        context 'when method annotation is missing' do
          it 'raises an error' do
            expect { variable.verify }.to raise_error(Exceptions::InvalidPolicyObject)
          end
        end

        context 'when method annotation is present' do
          let(:annotations) do
            {
              "#{Issuer::DYNAMIC_ANNOTATION_PREFIX}issuer" => issuer_id,
              "#{Issuer::DYNAMIC_ANNOTATION_PREFIX}method" => method
            }
          end

          context 'when issuer does not exist' do
            let(:issuer_dataset_double) { double('dataset_double', first: nil) }

            it 'raises an error' do
              expect { variable.verify }.to raise_error(Exceptions::PolicyLoadRecordNotFound)
            end
          end

          context 'when the user is not authorized to use the issuer' do
            let(:current_user_allowed_to_use_issuer) { false }

            it 'raises an error' do
              expect { variable.verify }.to raise_error(Exceptions::PolicyLoadRecordNotFound)
            end
          end

          context 'when issuer exists' do
            it 'is successfully verified' do
              expect { variable.verify }.to_not raise_error
            end
          end
        end
      end
    end

    context 'when variable is not a dynamic variable' do
      let(:resource_id) { 'myvariable' }

      context 'when issuer annotation is present' do
        let(:annotations) { { "#{Issuer::DYNAMIC_ANNOTATION_PREFIX}issuer" => issuer_id } }
        it 'raises an error' do
          expect { variable.verify }.to raise_error(Exceptions::InvalidPolicyObject)
        end
      end

      context 'when issuer annotation is not present' do
        let(:annotations) { {} }
        it 'is successfully verified' do
          expect { variable.verify }.to_not raise_error
        end
      end
    end
  end
end

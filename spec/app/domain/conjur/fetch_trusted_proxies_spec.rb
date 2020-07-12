# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Conjur::FetchTrustedProxies' do
  let(:valid_account) { 'valid-account' }
  let(:invalid_account) { 'invalid-account' }
  let(:mocked_account_validator) { double("ValidateAccountExists") }

  let(:valid_host) { "host/settings/trusted_proxies" }

  let(:mocked_role_class_empty_list) { double("RoleClass") }
  let(:mocked_role_empty_list) { double("RoleReturnsEmptyList") }
  let(:empty_trusted_proxies_list) { Array.new }


  before(:each) do
    allow(mocked_role_class_empty_list).to receive(:by_login)
                                           .with(valid_host, {:account=> valid_account})
                                           .and_return(mocked_role_empty_list)
    allow(mocked_role_empty_list).to receive(:restricted_to)
                                           .and_return(empty_trusted_proxies_list)

    allow(mocked_account_validator).to receive(:call)
                                           .with({:account=>valid_account})
                                           .and_return(true)
    allow(mocked_account_validator).to receive(:call)
                                           .with({:account=>invalid_account})
                                           .and_raise('ACCOUNT_NOT_EXIST_ERROR')
  end
  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A valid trusted proxies configuration" do
    subject do
      Conjur::FetchTrustedProxies.new(
          role_cls:                 mocked_role_class_empty_list,
          validate_account_exists:  mocked_account_validator,
      ).call(
          account: valid_account
      )
    end

    it "does not raise an error" do
      expect { subject }.to_not raise_error
    end
  end
end
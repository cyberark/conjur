# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Conjur::FetchTrustedProxies' do
  let(:valid_account) { 'valid-account' }
  let(:invalid_account) { 'invalid-account' }
  let(:mocked_account_validator) { double("ValidateAccountExists") }

  let(:valid_host) { "host/settings/trusted_proxies" }

  let(:ip_1) { Util::CIDR.new("1.0.0.0/8") }
  let(:ip_2) { Util::CIDR.new("1.2.3.0/24") }
  let(:ip_3) { Util::CIDR.new("1.2.3.4") }

  let(:mocked_role_class_empty_list) { double("RoleClass") }
  let(:mocked_role_empty_list) { double("RoleReturnsEmptyList") }
  let(:empty_trusted_proxies_list) { [] }

  let(:mocked_role_class_return_nil) { double("RoleClass") }
  let(:mocked_role_return_nil) { double("RoleReturnsNil") }

  let(:mocked_role_class_throw_error_in_restricted_to) { double("RoleClass") }
  let(:mocked_role_throw_error_in_restricted_to) { double("RoleRestrictedToError") }

  let(:mocked_role_class_throw_error_in_by_login) { double("RoleClassByLoginError") }

  let(:mocked_role_class_by_login_returns_nil_and_roleid_valid) { double("RoleClassByLoginNilAndRoleIdValid") }
  let(:mocked_role_class_by_login_returns_nil_and_roleid_nil) { double("RoleClassByLoginNilAndRoleIdNil") }
  let(:mocked_role_class_by_login_returns_nil_and_roleid_throws_error) { double("RoleClassByLoginNilAndRoleIdError") }

  let(:mocked_role_class_list_no_duplications) { double("RoleClass") }
  let(:mocked_role_list_no_duplications) { double("RoleReturnsListWithoutDuplications") }
  let(:trusted_proxies_list_no_duplications) { [ip_1, ip_2 , ip_3] }

  let(:mocked_role_class_list_duplications_1) { double("RoleClass") }
  let(:mocked_role_list_duplications_1) { double("RoleReturnsListWithDuplications") }
  let(:trusted_proxies_list_duplications_1) { [ip_1, ip_1 , ip_1] }
  let(:expected_list_1) { [trusted_proxies_list_duplications_1[0]] }

  let(:mocked_role_class_list_duplications_2) { double("RoleClass") }
  let(:mocked_role_list_duplications_2) { double("RoleReturnsListWithDuplications") }
  let(:trusted_proxies_list_duplications_2) { [ip_1, ip_2 , ip_3, ip_1, ip_2 , ip_3] }
  let(:expected_list_2) { [trusted_proxies_list_duplications_2[0],
                           trusted_proxies_list_duplications_2[1],
                           trusted_proxies_list_duplications_2[2]] }


  before(:each) do
    allow(mocked_role_class_empty_list).to receive(:by_login)
                                               .with(valid_host, {:account=> valid_account})
                                               .and_return(mocked_role_empty_list)
    allow(mocked_role_empty_list).to receive(:restricted_to)
                                         .and_return(empty_trusted_proxies_list)

    allow(mocked_role_class_throw_error_in_restricted_to).to receive(:by_login)
                                                                 .with(valid_host, {:account=> valid_account})
                                                                 .and_return(mocked_role_throw_error_in_restricted_to)
    allow(mocked_role_throw_error_in_restricted_to).to receive(:restricted_to)
                                                           .and_raise("DB_ERROR")

    allow(mocked_role_class_return_nil).to receive(:by_login)
                                               .with(valid_host, {:account=> valid_account})
                                               .and_return(mocked_role_return_nil)
    allow(mocked_role_return_nil).to receive(:restricted_to)
                                         .and_return(nil)

    allow(mocked_role_class_throw_error_in_by_login).to receive(:by_login)
                                                            .with(valid_host, {:account=> valid_account})
                                                            .and_raise("RoleNotFound")

    allow(mocked_role_class_by_login_returns_nil_and_roleid_valid).to receive(:by_login)
                                                                          .with(valid_host, {:account=> valid_account})
                                                                          .and_return(nil)
    allow(mocked_role_class_by_login_returns_nil_and_roleid_valid).to receive(:roleid_from_username)
                                                                          .with(valid_account, valid_host)
                                                                          .and_return("Valid Role")

    allow(mocked_role_class_by_login_returns_nil_and_roleid_nil).to receive(:by_login)
                                                                        .with(valid_host, {:account=> valid_account})
                                                                        .and_return(nil)
    allow(mocked_role_class_by_login_returns_nil_and_roleid_nil).to receive(:roleid_from_username)
                                                                        .with(valid_account, valid_host)
                                                                        .and_return(nil)

    allow(mocked_role_class_by_login_returns_nil_and_roleid_throws_error).to receive(:by_login)
                                                                                 .with(valid_host, {:account=> valid_account})
                                                                                 .and_return(nil)
    allow(mocked_role_class_by_login_returns_nil_and_roleid_throws_error).to receive(:roleid_from_username)
                                                                                 .with(valid_account, valid_host)
                                                                                 .and_raise("Error")

    allow(mocked_role_class_list_no_duplications).to receive(:by_login)
                                                         .with(valid_host, {:account=> valid_account})
                                                         .and_return(mocked_role_list_no_duplications)
    allow(mocked_role_list_no_duplications).to receive(:restricted_to)
                                                   .and_return(trusted_proxies_list_no_duplications)

    allow(mocked_role_class_list_duplications_1).to receive(:by_login)
                                                        .with(valid_host, {:account=> valid_account})
                                                        .and_return(mocked_role_list_duplications_1)
    allow(mocked_role_list_duplications_1).to receive(:restricted_to)
                                                  .and_return(trusted_proxies_list_duplications_1)

    allow(mocked_role_class_list_duplications_2).to receive(:by_login)
                                                        .with(valid_host, {:account=> valid_account})
                                                        .and_return(mocked_role_list_duplications_2)
    allow(mocked_role_list_duplications_2).to receive(:restricted_to)
                                                  .and_return(trusted_proxies_list_duplications_2)

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
    context "trusted proxies contains an empty list of IPs addresses" do
      context "when role.restricted_to returns empty array" do
        subject do
          Conjur::FetchTrustedProxies.new(
              role_cls:                 mocked_role_class_empty_list,
              validate_account_exists:  mocked_account_validator,
              ).call(
              account: valid_account
          )
        end

        it "returns an empty list" do
          expect( subject ).to eq(empty_trusted_proxies_list)
        end
      end

      context "when role.restricted_to returns nil" do
        subject do
          Conjur::FetchTrustedProxies.new(
              role_cls:                 mocked_role_class_return_nil,
              validate_account_exists:  mocked_account_validator,
              ).call(
              account: valid_account
          )
        end

        it "returns an empty list" do
          expect( subject ).to eq(empty_trusted_proxies_list)
        end
      end
    end

    context "trusted proxies contains an list of IPs addresses without duplications" do
      subject do
        Conjur::FetchTrustedProxies.new(
            role_cls:                 mocked_role_class_list_no_duplications,
            validate_account_exists:  mocked_account_validator,
            ).call(
            account: valid_account
        )
      end

      it "returns expected list" do
        expect( subject ).to eq(trusted_proxies_list_no_duplications)
      end
    end

    context "trusted proxies contains an list of IPs addresses with duplications" do
      context "with 1 same IP address" do
        subject do
          Conjur::FetchTrustedProxies.new(
              role_cls:                 mocked_role_class_list_duplications_1,
              validate_account_exists:  mocked_account_validator,
              ).call(
              account: valid_account
          )
        end

        it "returns list with no duplication" do
          expect( subject ).to eq(expected_list_1)
        end
      end

      context "with 3 same IP addresses" do
        subject do
          Conjur::FetchTrustedProxies.new(
              role_cls:                 mocked_role_class_list_duplications_2,
              validate_account_exists:  mocked_account_validator,
              ).call(
              account: valid_account
          )
        end

        it "returns list with no duplication" do
          expect( subject ).to eq(expected_list_2)
        end
      end
    end
  end

  context "An invalid account input" do
    subject do
      Conjur::FetchTrustedProxies.new(
          role_cls:                 mocked_role_class_empty_list,
          validate_account_exists:  mocked_account_validator,
          ).call(
          account: invalid_account
      )
    end

    it "raises an error" do
      expect { subject }.to raise_error(::Errors::Conjur::TrustedProxiesMissing)
    end
  end

  context "An invalid trusted proxies configuration" do
    context "when role.restricted_to throws an error" do
      subject do
        Conjur::FetchTrustedProxies.new(
            role_cls:                 mocked_role_class_throw_error_in_restricted_to,
            validate_account_exists:  mocked_account_validator,
            ).call(
            account: valid_account
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(::Errors::Conjur::TrustedProxiesMissing)
      end
    end

    context "when role_cls.by_login throws an error" do
      subject do
        Conjur::FetchTrustedProxies.new(
            role_cls:                 mocked_role_class_throw_error_in_by_login,
            validate_account_exists:  mocked_account_validator,
            ).call(
            account: valid_account
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(::Errors::Conjur::TrustedProxiesMissing)
      end
    end

    context "when role_cls.by_login returns nil" do
      context "then role_cls.roleid_from_username returns valid role" do
        subject do
          Conjur::FetchTrustedProxies.new(
              role_cls:                 mocked_role_class_by_login_returns_nil_and_roleid_valid,
              validate_account_exists:  mocked_account_validator,
              ).call(
              account: valid_account
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(::Errors::Conjur::TrustedProxiesMissing)
        end
      end

      context "then role_cls.roleid_from_username returns nil" do
        subject do
          Conjur::FetchTrustedProxies.new(
              role_cls:                 mocked_role_class_by_login_returns_nil_and_roleid_nil,
              validate_account_exists:  mocked_account_validator,
              ).call(
              account: valid_account
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(::Errors::Conjur::TrustedProxiesMissing)
        end
      end

      context "then role_cls.roleid_from_username returns nil" do
        subject do
          Conjur::FetchTrustedProxies.new(
              role_cls:                 mocked_role_class_by_login_returns_nil_and_roleid_throws_error,
              validate_account_exists:  mocked_account_validator,
              ).call(
              account: valid_account
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(::Errors::Conjur::TrustedProxiesMissing)
        end
      end
    end
  end
end
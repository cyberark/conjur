# frozen_string_literal: true

require 'spec_helper'
require 'ipaddr'

RSpec.describe 'Conjur::ValidateTrustedProxies' do
  let(:valid_account) {'valid-account'}

  let(:trusted_proxies_1_cidr_32) {Util::CIDR.new(IPAddr.new("1.0.0.1/32"))}
  let(:trusted_proxies_1_cidr_24) {Util::CIDR.new(IPAddr.new("1.0.0.0/24"))}
  let(:trusted_proxies_1_cidr_8) {Util::CIDR.new(IPAddr.new("1.0.0.0/8"))}

  let(:trusted_proxies_2_cidr_24) {Util::CIDR.new(IPAddr.new("2.0.0.0/24"))}
  let(:trusted_proxies_3_cidr_24) {Util::CIDR.new(IPAddr.new("3.0.0.0/24"))}


  let(:valid_proxy_ip_1) {IPAddr.new("1.0.0.1")}
  let(:valid_proxy_ip_2) {IPAddr.new("2.0.0.2")}
  let(:valid_proxy_ip_3) {IPAddr.new("3.0.0.3")}

  let(:invalid_proxy_ip_4) {IPAddr.new("4.0.0.4")}

  let(:empty_proxy_list) {[]}
  let(:empty_trusted_proxy_list) {[]}

  let(:proxy_list_with_1_ip_valid) {[valid_proxy_ip_1]}

  let(:proxy_list_with_4_ip_invalid) {[invalid_proxy_ip_4]}

  let(:trusted_proxies_list_1_cidr_32) {[trusted_proxies_1_cidr_32]}
  let(:trusted_proxies_list_1_cidr_24) {[trusted_proxies_1_cidr_24]}
  let(:trusted_proxies_list_1_cidr_8) {[trusted_proxies_1_cidr_8]}

  let(:trusted_proxies_list_3_ranges) {[trusted_proxies_1_cidr_24,
                                        trusted_proxies_2_cidr_24,
                                        trusted_proxies_3_cidr_24]}

  let(:proxy_list_with_3_valid) {[valid_proxy_ip_1,
                                  valid_proxy_ip_2,
                                  valid_proxy_ip_3]}

  let(:proxy_list_with_1_invalid_in_the_middle) {[valid_proxy_ip_1,
                                                  valid_proxy_ip_2,
                                                  invalid_proxy_ip_4,
                                                  valid_proxy_ip_1,
                                                  valid_proxy_ip_2,]}


  let(:mocked_fetch_trusted_proxy_empty_list) {double("EmptyTrustedProxiesList")}
  let(:mocked_fetch_trusted_proxy_returns_error) {double("EmptyTrustedProxiesList")}

  let(:mocked_fetch_trusted_proxy_returns_1_cidr_32) {double("TrustedProxiesListContains1CIDR32")}
  let(:mocked_fetch_trusted_proxy_returns_1_cidr_24) {double("TrustedProxiesListContains1CIDR24")}
  let(:mocked_fetch_trusted_proxy_returns_1_cidr_8) {double("TrustedProxiesListContains1CIDR8")}
  let(:mocked_fetch_trusted_proxy_returns_3_ranges) {double("TrustedProxiesListContains3Ranges")}
  let(:mocked_fetch_trusted_proxy_returns_5_ranges) {double("TrustedProxiesListContains3Ranges")}

  before(:each) do
    allow(mocked_fetch_trusted_proxy_empty_list).to receive(:call)
                                                        .with({:account => valid_account})
                                                        .and_return(empty_trusted_proxy_list)

    allow(mocked_fetch_trusted_proxy_returns_error).to receive(:call)
                                                           .with({:account => valid_account})
                                                           .and_raise(::Errors::Conjur::TrustedProxiesFetchFailed)

    allow(mocked_fetch_trusted_proxy_returns_error).to receive(:call)
                                                           .with({:account => valid_account})
                                                           .and_raise(::Errors::Conjur::TrustedProxiesFetchFailed)

    allow(mocked_fetch_trusted_proxy_returns_1_cidr_32).to receive(:call)
                                                               .with({:account => valid_account})
                                                               .and_return(trusted_proxies_list_1_cidr_32)
    allow(mocked_fetch_trusted_proxy_returns_1_cidr_24).to receive(:call)
                                                               .with({:account => valid_account})
                                                               .and_return(trusted_proxies_list_1_cidr_24)
    allow(mocked_fetch_trusted_proxy_returns_1_cidr_8).to receive(:call)
                                                              .with({:account => valid_account})
                                                              .and_return(trusted_proxies_list_1_cidr_8)

    allow(mocked_fetch_trusted_proxy_returns_3_ranges).to receive(:call)
                                                              .with({:account => valid_account})
                                                              .and_return(trusted_proxies_list_3_ranges)
  end
  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "An error in fetching trusted list" do
    subject do
      Conjur::ValidateTrustedProxies.new(
          fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_error
      ).call(
          account: valid_account,
          proxy_list: proxy_list_with_1_ip_valid
      )
    end

    it "raises an error" do
      expect {subject}.to raise_error(::Errors::Conjur::TrustedProxiesFetchFailed)
    end
  end

  context "A valid proxy list" do
    context "when trusted proxy list configured to be empty" do
      subject do
        Conjur::ValidateTrustedProxies.new(
            fetch_trusted_proxies: mocked_fetch_trusted_proxy_empty_list
        ).call(
            account: valid_account,
            proxy_list: proxy_list_with_1_ip_valid
        )
      end

      it "validates without error" do
        expect {subject}.to_not raise_error
      end
    end

    context "when input proxy list is empty" do
      subject do
        Conjur::ValidateTrustedProxies.new(
            fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_1_cidr_32
        ).call(
            account: valid_account,
            proxy_list: empty_proxy_list
        )
      end

      it "validates without error" do
        expect {subject}.to_not raise_error
      end
    end

    context "when input proxy contains 1 valid ip address" do
      context "and trusted proxy list contains 1 cidr 32 ip range" do
        subject do
          Conjur::ValidateTrustedProxies.new(
              fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_1_cidr_32
          ).call(
              account: valid_account,
              proxy_list: proxy_list_with_1_ip_valid
          )
        end

        it "validates without error" do
          expect {subject}.to_not raise_error
        end
      end

      context "and trusted proxy list contains 1 cidr 24 ip range" do
        subject do
          Conjur::ValidateTrustedProxies.new(
              fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_1_cidr_24
          ).call(
              account: valid_account,
              proxy_list: proxy_list_with_1_ip_valid
          )
        end

        it "validates without error" do
          expect {subject}.to_not raise_error
        end
      end

      context "and trusted proxy list contains 1 cidr 8 ip range" do
        subject do
          Conjur::ValidateTrustedProxies.new(
              fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_1_cidr_8
          ).call(
              account: valid_account,
              proxy_list: proxy_list_with_1_ip_valid
          )
        end

        it "validates without error" do
          expect {subject}.to_not raise_error
        end
      end

      context "and trusted proxy list contains 3 ip ranges" do
        subject do
          Conjur::ValidateTrustedProxies.new(
              fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_3_ranges
          ).call(
              account: valid_account,
              proxy_list: proxy_list_with_1_ip_valid
          )
        end

        it "validates without error" do
          expect {subject}.to_not raise_error
        end
      end
    end

    context "when input proxy contains 3 valid ip address" do
      context "and trusted proxy list contains 3 ip addresses" do
        subject do
          Conjur::ValidateTrustedProxies.new(
              fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_3_ranges
          ).call(
              account: valid_account,
              proxy_list: proxy_list_with_3_valid
          )
        end

        it "validates without error" do
          expect {subject}.to_not raise_error
        end
      end
    end
  end

  context "An invalid proxy list" do
    context "when input proxy contains 1 invalid ip address" do
      context "and trusted proxy list contains 1 cidr 32 ip range" do
        subject do
          Conjur::ValidateTrustedProxies.new(
              fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_1_cidr_32
          ).call(
              account: valid_account,
              proxy_list: proxy_list_with_4_ip_invalid
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(::Errors::Conjur::InvalidProxy)
        end
      end

      context "and trusted proxy list contains 1 cidr 24 ip range" do
        subject do
          Conjur::ValidateTrustedProxies.new(
              fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_1_cidr_24
          ).call(
              account: valid_account,
              proxy_list: proxy_list_with_4_ip_invalid
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(::Errors::Conjur::InvalidProxy)
        end
      end

      context "and trusted proxy list contains 1 cidr 8 ip range" do
        subject do
          Conjur::ValidateTrustedProxies.new(
              fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_1_cidr_8
          ).call(
              account: valid_account,
              proxy_list: proxy_list_with_4_ip_invalid
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(::Errors::Conjur::InvalidProxy)
        end
      end

      context "and trusted proxy list contains 3 ip ranges" do
        subject do
          Conjur::ValidateTrustedProxies.new(
              fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_3_ranges
          ).call(
              account: valid_account,
              proxy_list: proxy_list_with_4_ip_invalid
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(::Errors::Conjur::InvalidProxy)
        end
      end
    end

    context "when input proxy contains 5 ip address with 1 invalid" do
      context "and trusted proxy list contains 3 ip addresses" do
        subject do
          Conjur::ValidateTrustedProxies.new(
              fetch_trusted_proxies: mocked_fetch_trusted_proxy_returns_3_ranges
          ).call(
              account: valid_account,
              proxy_list: proxy_list_with_1_invalid_in_the_middle
          )
        end

        it "validates without error" do
          expect {subject}.to raise_error(::Errors::Conjur::InvalidProxy)
        end
      end
    end
  end
end


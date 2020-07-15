# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Security::ExtractRequestOriginIpAddrInfo do

  def client_ip
    '1.1.1.1'
  end

  def remote_addr
    '2.2.2.2'
  end

  def proxy_1
    '3.3.3.3'
  end

  def proxy_2
    '4.4.4.4'
  end


  def request_with_empty_xff
    double('request_with_empty_xff').tap do |request|
      allow(request).to receive(:headers).and_return(request)
      allow(request).to receive(:[]).and_return(nil)
      allow(request).to receive(:remote_addr).and_return(remote_addr)
    end
  end

  def request_with_single_entry_xff
    double('request_with_single_entry_xff').tap do |request|
      allow(request).to receive(:headers).and_return(request)
      allow(request).to receive(:[]).and_return(proxy_1)
      allow(request).to receive(:remote_addr).and_return(remote_addr)
    end
  end

  def request_with_multi_entries_xff
    double('request_with_multi_entries_xff').tap do |request|
      allow(request).to receive(:headers).and_return(request)
      allow(request).to receive(:[]).and_return(client_ip + ', ' + proxy_2, + ', ' + proxy_2)
      allow(request).to receive(:remote_addr).and_return(remote_addr)
    end
  end


  def request_with_duplicate_client_ip_in_xff
    double('request_with_multi_entries_xff').tap do |request|
      allow(request).to receive(:headers).and_return(request)
      allow(request).to receive(:[]).and_return(client_ip + ', ' + proxy_2, + ', ' + client_ip)
      allow(request).to receive(:remote_addr).and_return(remote_addr)
    end
  end

  context "A request with an empty X-Forwarded-For header" do
    subject do
      Authentication::Security::ExtractRequestOriginIpAddrInfo.new
      .call(
        request: request_with_empty_xff
      )
    end

    it "process without error" do
      expect { subject }.to_not raise_error
    end

    it "returns the right remote_addr as the client_ip" do
      expect(subject.client_ip).to be(remote_addr)
    end

    it "returns an empty proxy list" do
      expect(subject.xff_ip_list.empty?).to be_truthy
    end
  end

  context "A request with a single entry in X-Forwarded-For header" do
    subject do
      Authentication::Security::ExtractRequestOriginIpAddrInfo.new
      .call(
        request: request_with_single_entry_xff
      )
    end

    it "process without error" do
      expect { subject }.to_not raise_error
    end

    it "returns the right remote_addr as client_ip" do
      expect(subject.client_ip).to eq(proxy_1)
    end

    it "it a proxy list with a single element" do
      expect(subject.xff_ip_list.length).to eq(1)
    end

    it "returns the remote_addr in proxy list" do
      expect(subject.xff_ip_list[0]).to be(remote_addr)
    end
  end

  context "A request with a multi entries in X-Forwarded-For header" do
    subject do
      Authentication::Security::ExtractRequestOriginIpAddrInfo.new
      .call(
        request: request_with_multi_entries_xff
      )
    end

    it "process without error" do
      expect { subject }.to_not raise_error
    end

    it "returns the first entry from XFF header as the client_ip" do
      expect(subject.client_ip).to eq(client_ip)
    end

    it "it removes duplicates from proxy list" do
      expect(subject.xff_ip_list.length).to eq(2)
    end

    it "returns an non empty proxy set with the right values" do
      expect(subject.xff_ip_list).to eq([proxy_2, remote_addr])
    end
  end

  context "A request with a duplicate client ip in X-Forwarded-For header" do
    subject do
      Authentication::Security::ExtractRequestOriginIpAddrInfo.new
        .call(
          request: request_with_duplicate_client_ip_in_xff
        )
    end

    it "process without error" do
      expect { subject }.to_not raise_error
    end

    it "returns the first entry from XFF header as the client_ip" do
      expect(subject.client_ip).to eq(client_ip)
    end

    it "it removes duplicates from proxy list" do
      expect(subject.xff_ip_list.length).to eq(2)
    end

    it "returns an non empty proxy set with the right values" do
      expect(subject.xff_ip_list).to eq([proxy_2, remote_addr])
    end
  end
end

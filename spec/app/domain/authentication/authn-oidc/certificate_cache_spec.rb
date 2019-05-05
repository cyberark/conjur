# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe 'Authentication::AuthnOidc::CertificateCache' do
  context "When testing the CertificateCache class" do
    it "should return 'some_value' when we call fetch with block that returns 'some_value'" do
      cert_cache = Authentication::AuthnOidc::CertificateCache.instance
      cert_cache.clear_all
      val = cert_cache.fetch "my_key", false do
        "some_value"
      end
      expect(val).to eq "some_value"
    end

    it "returns same value when we call fetch with same key more than once" do
      cert_cache = Authentication::AuthnOidc::CertificateCache.instance
      cert_cache.clear_all
      value1_ref = [10]
      value2_ref = [20]
      fetch_and_verify cert_cache, "key1", value1_ref, 1
      fetch_and_verify cert_cache, "key2", value2_ref, 1
      fetch_and_verify cert_cache, "key2", value2_ref, 0
      fetch_and_verify cert_cache, "key2", value2_ref, 0
      fetch_and_verify cert_cache, "key1", value1_ref, 0
      fetch_and_verify cert_cache, "key1", value1_ref, 0
    end


    it "fetch same value when call again without read" do
      cert_cache = Authentication::AuthnOidc::CertificateCache.instance
      cert_cache.clear_all
      value1_ref = [10]
      value2_ref = [20]
      fetch_and_verify cert_cache, "key1", value1_ref, 1
      fetch_and_verify cert_cache, "key2", value2_ref, 1
      expect(cert_cache.fetch "key1").to eq 11
      expect(cert_cache.fetch "key2").to eq 21
    end

    it "return different value when called fetch-delete-fetch with same key more than once" do
      cert_cache = Authentication::AuthnOidc::CertificateCache.instance
      cert_cache.clear_all
      value1_ref = [10]
      fetch_and_verify cert_cache, "key1", value1_ref, 1
      cert_cache.clear_all
      fetch_and_verify cert_cache, "key1", value1_ref, 1
      fetch_and_verify cert_cache, "key1", value1_ref, 0
    end

    it "should read 3 times when try reading more than 3 times" do
      cert_cache = Authentication::AuthnOidc::CertificateCache.instance
      cert_cache.clear_all
      value1_ref = [10]
      value2_ref = [20]
      force_read_and_verify cert_cache, "key1", value1_ref, 1
      force_read_and_verify cert_cache, "key1", value1_ref, 1
      force_read_and_verify cert_cache, "key1", value1_ref, 1
      force_read_and_verify cert_cache, "key1", value1_ref, 1
      force_read_and_verify cert_cache, "key1", value1_ref, 0
      fetch_and_verify cert_cache, "key2", value2_ref, 1
      force_read_and_verify cert_cache, "key2", value2_ref, 1
      force_read_and_verify cert_cache, "key1", value1_ref, 0
      force_read_and_verify cert_cache, "key2", value2_ref, 1
      force_read_and_verify cert_cache, "key2", value2_ref, 1
      force_read_and_verify cert_cache, "key2", value2_ref, 0

    end

    it "should force_read recover after retries_time_lap has elapsed" do
      cert_cache = Authentication::AuthnOidc::CertificateCache.instance
      cert_cache.clear_all
      original_retries_time_lap = cert_cache.RETRIES_TIME_LAP
      cert_cache.RETRIES_TIME_LAP = 1
      value1_ref = [10]
      value2_ref = [20]

      fetch_and_verify cert_cache, "key1", value1_ref, 1
      fetch_and_verify cert_cache, "key2", value2_ref, 1
      for i in 1..2 do
        force_read_and_verify cert_cache, "key1", value1_ref, 1
        force_read_and_verify cert_cache, "key2", value2_ref, 1
        force_read_and_verify cert_cache, "key1", value1_ref, 1
        force_read_and_verify cert_cache, "key1", value1_ref, 1
        force_read_and_verify cert_cache, "key2", value2_ref, 1
        force_read_and_verify cert_cache, "key1", value1_ref, 0
        sleep 2
        force_read_and_verify cert_cache, "key1", value1_ref, 1
        force_read_and_verify cert_cache, "key2", value2_ref, 1
        force_read_and_verify cert_cache, "key1", value1_ref, 1
        force_read_and_verify cert_cache, "key2", value2_ref, 1
        force_read_and_verify cert_cache, "key1", value1_ref, 1
        force_read_and_verify cert_cache, "key1", value1_ref, 0
        force_read_and_verify cert_cache, "key2", value2_ref, 1
        force_read_and_verify cert_cache, "key2", value2_ref, 0
        force_read_and_verify cert_cache, "key2", value2_ref, 0
        sleep 2
      end
      cert_cache.RETRIES_TIME_LAP = original_retries_time_lap
    end

    private

    def force_read_and_verify cache, key, value_ref, expected_inc = 0
      init_value = value_ref[0]
      val = cache.fetch key, true do
        value_ref[0] = value_ref[0] + 1
      end
      expect(value_ref[0]).to eq (init_value + expected_inc)
    end

    def fetch_and_verify cache, key, value_ref, expected_inc = 0
      init_value = value_ref[0]
      val = cache.fetch key, false do
        value_ref[0] = value_ref[0] + 1
      end
      expect(value_ref[0]).to eq (init_value + expected_inc)
    end

  end
end
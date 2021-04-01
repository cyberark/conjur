# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnAzure::DecodedToken') do
  def decoded_token_hash(token_str)
    JSON.parse(token_str).to_hash
  end

  let(:decoded_token_hash_valid) do
    decoded_token_hash(
      "{\"xms_mirid\": \"some_xms_mirid_value\", \"oid\": \"some_oid_value\"}"
    )
  end

  let(:decoded_token_hash_missing_xms_mirid) do
    decoded_token_hash(
      "{\"oid\": \"some_oid_value\"}"
    )
  end

  let(:decoded_token_hash_missing_oid) do
    decoded_token_hash(
      "{\"xms_mirid\": \"some_xms_mirid_value\"}"
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A decoded token" do
    context "with required fields" do
      subject(:decoded_token) do
        ::Authentication::AuthnAzure::DecodedToken.new(
          decoded_token_hash: decoded_token_hash_valid,
          logger: Rails.logger
        )
      end

      it "does not raise an error" do
        expect { decoded_token }.to_not raise_error
      end

      it "parses the token expectedly" do
        expect(decoded_token.xms_mirid).to eq("some_xms_mirid_value")
        expect(decoded_token.oid).to eq("some_oid_value")
      end
    end

    context "that is missing the xms_mirid field" do
      subject do
        ::Authentication::AuthnAzure::DecodedToken.new(
          decoded_token_hash: decoded_token_hash_missing_xms_mirid,
          logger: Rails.logger
        )
      end

      it "raises a TokenClaimNotFoundOrEmpty error" do
        expect { subject }.to raise_error(
          ::Errors::Authentication::Jwt::TokenClaimNotFoundOrEmpty
        )
      end
    end

    context "that is missing the oid field" do
      subject do
        ::Authentication::AuthnAzure::DecodedToken.new(
          decoded_token_hash: decoded_token_hash_missing_oid,
          logger: Rails.logger
        )
      end

      it "raises a TokenClaimNotFoundOrEmpty error" do
        expect { subject }.to raise_error(
          ::Errors::Authentication::Jwt::TokenClaimNotFoundOrEmpty
        )
      end
    end
  end
end

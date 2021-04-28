# frozen_string_literal: true
require 'spec_helper'
RSpec.describe(Authentication::AuthnJwt::JWTConfigurationDummyVendor) do

  it "return cucumber on get_identity" do
    dummy_jwt_configuration = ::Authentication::AuthnJwt::JWTConfigurationDummyVendor
    expect(dummy_jwt_configuration.conjur_id).to eq "cucumber"
  end

  it "return true on validate_restrictions" do
    dummy_jwt_configuration = ::Authentication::AuthnJwt::JWTConfigurationDummyVendor
    expect(dummy_jwt_configuration.validate_restrictions).to eq true
  end

  it "return true on validate_and_decode_token" do
    dummy_jwt_configuration = ::Authentication::AuthnJwt::JWTConfigurationDummyVendor
    expect(dummy_jwt_configuration.validate_and_decode_token("DummyToken")).to eq true
  end

end

# frozen_string_literal: true
require 'spec_helper'
RSpec.describe(Authentication::AuthnJwt::JWTConfigurationDummyVendor) do

  it "return cucumber on get_identity" do
    dummy_jwt_configuration = ::Authentication::AuthnJwt::JWTConfigurationDummyVendor.new
    expect(dummy_jwt_configuration.get_identity).to eq "cucumber"
  end

  it "return true on validate_restrictions" do
    dummy_jwt_configuration = ::Authentication::AuthnJwt::JWTConfigurationDummyVendor.new
    expect(dummy_jwt_configuration.validate_restrictions).to eq true
  end

  it "return true on validate_and_decode" do
    dummy_jwt_configuration = ::Authentication::AuthnJwt::JWTConfigurationDummyVendor.new
    expect(dummy_jwt_configuration.validate_and_decode).to eq true
  end

end

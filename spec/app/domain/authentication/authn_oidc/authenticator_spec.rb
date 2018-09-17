# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnOidc::Authenticator do
  def non_equal_id_token_subject
    "other-sub"
  end

  def valid_user_info_subject
    "some-sub"
  end

  def valid_user_info
    double('user_info',
            sub: valid_user_info_subject,
            preferred_username: "non_nil_value"
          )
  end

  def no_profile_scope_user_info
    double('user_info',
            sub: valid_user_info_subject,
            preferred_username: nil
          )
  end

  let (:authenticator_instance) do
    Authentication::AuthnOidc::Authenticator.new(env:[])
  end

  it "validates user_info with valid value" do
    subject = authenticator_instance
    expect { subject.send(:validate_user_info, valid_user_info, valid_user_info_subject) }.to_not raise_error
  end

  it "fails non-equal subject" do
    subject = authenticator_instance
    expect { subject.send(:validate_user_info, valid_user_info, non_equal_id_token_subject) }.to raise_error(
      Authentication::AuthnOidc::OIDCAuthenticationError
    )
  end

  it "fails user_info without preferred_username" do
    subject = authenticator_instance
    expect { subject.send(:validate_user_info, no_profile_scope_user_info, valid_user_info_subject) }.to raise_error(
      Authentication::AuthnOidc::OIDCAuthenticationError
    )
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::Default::InitializeDefaultAuth) do
  it_behaves_like "auth initializer"
  let(:auth_name) { "authn-oidc" }
  let(:current_user) { double("User") }

  subject do
    Authentication::Default::InitializeDefaultAuth.new(
      secret: secret
    ).(
      conjur_account: account,
      service_id: service_id,
      auth_data: auth_data,
      current_user: current_user
    )
  end

end

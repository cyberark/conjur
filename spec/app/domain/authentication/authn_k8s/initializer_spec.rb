# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnK8s::InitializeK8sAuth) do
  it_behaves_like "auth initializer" do
    def variable_regex(variable_name)
      /#{account}:variable:conjur\/#{auth_name}\/#{service_id}\/kubernetes\/#{variable_name}/
    end
  end

  let(:auth_name) { "authn-k8s" }
  let(:ca_repo) { double(Repos::ConjurCA).tap do |repo|
    expect(repo).to receive(:create).with(/#{account}:webservice:conjur\/#{auth_data.auth_name}\/#{service_id}/) unless auth_data.nil?
  end }
  let(:current_user) { double("User") }

  subject do
    Authentication::AuthnK8s::InitializeK8sAuth.new(
      conjur_ca_repo: ca_repo,
      secret: secret
    ).(
      conjur_account: account,
      service_id: service_id,
      auth_data: auth_data,
      current_user: current_user
    )
  end

end

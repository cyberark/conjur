# frozen_string_literal: true

require 'spec_helper'

describe(Authentication::AuthnK8s::ValidateStatus) do
  subject do
    Authentication::AuthnK8s::ValidateStatus.new
  end

  let(:account) { 'rspec' }
  let(:service_id) { 'test'}

  # Currently, this validate status implementation does nothing and simply
  # allows the status endpoint to function for the Kubernetes authenticator.
  # Subsequent stories will add Kubernetes specific validations here that will
  # be tested in these specs.
  it 'does not raise an error' do
    expect do
      subject.call(account: account, service_id: service_id)
    end.not_to raise_error
  end
end

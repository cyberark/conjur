# frozen_string_literal: true

require 'spec_helper'

shared_examples_for "structured data includes client IP address" do
  it 'contains the client IP address' do
    expect(subject.structured_data).to match(hash_including({
      Audit::SDID::CLIENT => { ip: client_ip }
    }))
  end
end

# frozen_string_literal: true

require 'spec_helper'

# It should not really matter which paths we test since the problematic
# parsing of the body happens before the controller is even created and we
# want to make sure it's disabled globally.

describe 'POST handler', type: :request do
  it 'does not interpret an urlencoded body' do
    post '/the/path/does/not/really/matter', 'secret-api-key'
    expect(request.params.to_s).to_not include 'secret-api-key'
  end

  it 'does not interpret a JSON body' do
    post '/some/path', '{ "secretkey": "here" }',
      'Content-Type': 'application/json'
    expect(request.params.to_s).to_not include 'secretkey'
  end

  it 'does not interpret a body with multipart/mixed type' do
    post '/some/path', '{ "secretkey": "here" }',
      'Content-Type': 'multipart/mixed'
    expect(request.params.to_s).to_not include 'secretkey'
  end
end

# frozen_string_literal: true

require 'spec_helper'

# It should not really matter which paths we test since the problematic
# parsing of the body happens before the controller is even created and we
# want to make sure it's disabled globally.

describe 'POST handler', type: :request do
  it 'does not interpret an urlencoded body' do
    some_secret = 'my-secret-api-key'
    post('/doesnt/matter', params: some_secret, as: :text)
    expect(secret_logged?(some_secret)).to be(false)
  end

  it 'does not interpret a JSON body' do
    some_secret = 'my-secret-api-key'
    post(
      '/doesnt/matter',
      params: "{ \"secretkey\": \"#{some_secret}\" }",
      as: :json
    )
    expect(secret_logged?(some_secret)).to be(false)
  end
end

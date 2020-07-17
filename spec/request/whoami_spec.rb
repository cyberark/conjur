# frozen_string_literal: true

require 'spec_helper'

describe StatusController, type: :request do
  describe "GET #whoami" do
    it "responds with unauthorized when no access token is provided" do
      get '/whomai'
      expect(response.status).to equal(401)
    end

    it "returns the client information" do
      request_env = {
        'HTTP_AUTHORIZATION' => access_token_for('alice'),
        'REMOTE_ADDR' => '4.4.4.4'
      }
      
      get('/whoami', env: request_env)

      response_json = JSON.parse(response.body)
      expect(response_json).to include({
        'client_ip' => '4.4.4.4',
        'account' => 'rspec',
        'username' => 'alice'
      })
    end
  end
end

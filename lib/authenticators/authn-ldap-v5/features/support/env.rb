ENV['RACK_ENV'] = 'test'
require 'logger'
require 'rspec'
require 'json'
require 'base64'
require 'conjur/api'

$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))
Conjur.configuration.account = 'cucumber'

class ConjurToken
  def initialize(raw_token)
    @token = JSON.parse(raw_token)
  end

  def login
    payload['sub']
  end

  private

  def payload
    @payload ||= JSON.parse(Base64.decode64(@token['payload']))
  end
end

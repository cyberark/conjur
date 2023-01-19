# frozen_string_literal: true

class ConjurToken
  attr_reader :token

  def initialize(raw_token)
    @token = JSON.parse(raw_token)
  end

  def username
    payload['sub']
  end

  private

  def payload
    @payload ||= JSON.parse(Base64.decode64(@token['payload']))
  end
end

# frozen_string_literal: true

require 'base64'

class String
  def encode64
    Base64::strict_encode64(self)
  end

  def decode64
    Base64::strict_decode64(self)
  end
end

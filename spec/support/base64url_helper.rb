# frozen_string_literal: true

require 'spec_helper'

shared_context "base64url" do

  def base64_url_decode(str)
    str += '=' * (4 - str.length.modulo(4))
    Base64.decode64(str.tr('-_','+/'))
  end

  def base64_url_encode(str)
    Base64.strict_encode64(str).tr('+/','-_').tr('=','')
  end

end

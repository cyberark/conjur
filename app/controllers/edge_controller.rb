# frozen_string_literal: true

class EdgeController < ApplicationController
  def show
    Rails.logger.info("+++++++++++ 1 ++++++++++")
    accountName = params[:account]
    Rails.logger.info("+++++++++++ accountName = #{accountName}")

    accounts = []
    Slosilo.each do |k,v|
      accounts << k
      Rails.logger.info("+++++++++++ k = #{k}, v = #{v}")
    end

    accountKey = "authn:" + accountName
    Rails.logger.info("+++++++++++ accountKey = #{accountKey}")
    key = Slosilo[accountKey]
    Rails.logger.info("+++++++++++ publicKey = #{key.to_s()}")
    Rails.logger.info("+++++++++++ publicKey.fingerprint = #{key.fingerprint}")
    Rails.logger.info("+++++++++++ Slosilo[accountKey].private? = #{Slosilo[accountKey].private?}")
    privateKey = Slosilo[accountKey].to_der.unpack("H*").first
    Rails.logger.info("+++++++++++ privateKey = #{privateKey}")

    result = "{\"account\": \"" + accountKey + "\", \"key\": \"" + privateKey + "\", \"fingerprint\": \"" + key.fingerprint + "\" }"

    render(plain: result, content_type: "text/plain")
  end
end

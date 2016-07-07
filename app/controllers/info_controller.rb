class InfoController < ApplicationController
  def show
    render json: { account: default_account }
  end
end
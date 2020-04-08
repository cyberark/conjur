# frozen_string_literal: true

class StatusController < ApplicationController
  def index
    render 'index', layout: false
  end

end

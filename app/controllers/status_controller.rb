# frozen_string_literal: true

require 'date'

class StatusController < ApplicationController
  include TokenUser
  include ::ActionView::Layouts

  def index
    render('index', layout: false)
  end
end

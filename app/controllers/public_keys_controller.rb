# frozen_string_literal: true

class PublicKeysController < ApplicationController
  def show
    account, kind, id = [ params[:account], params[:kind], params[:identifier] ]

    values = Secret.latest_public_keys account, kind, id
    # For test stability.
    values.sort! if %w[test development].member?(Rails.env)
    result = values.map(&:strip).join("\n").strip + "\n"

    render plain: result, content_type: "text/plain"
  end
end

# frozen_string_literal: true

Dummy::Application.config.secret_key_base = Object.new.tap do |o|
  def o.to_str
    raise "secret_key_base is intentionally not set for this application"
  end
end

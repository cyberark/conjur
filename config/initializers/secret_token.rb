Possum::Application.config.secret_key_base = Object.new.tap do |o|
  def o.to_str
    fail "secret key base not set for this application"
  end
end

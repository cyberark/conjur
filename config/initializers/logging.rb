Rails.application.configure do

  config.log_tags = [
    lambda { |request| "origin=#{request.ip}" },
    lambda { |request| "req_id=#{request.uuid}" }
  ]

end
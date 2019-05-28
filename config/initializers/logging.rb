Rails.application.configure do

  config.log_tags = [
    "pid:#{$$}",
    "tid:#{Thread.current.object_id}",
    lambda { |request| "origin:#{request.ip}" },
    lambda { |request| "req_id:#{request.uuid}" }
  ]

end
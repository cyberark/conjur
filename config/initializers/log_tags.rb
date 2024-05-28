Rails.application.configure do
  def gettid
    Thread.current.native_thread_id
  end

  config.log_tags = [
    ->(request) { "origin=#{request.ip}" },
    ->(request) { "request_id=#{request.uuid}" }
  ]

  config.log_tags << proc { "tid=#{gettid}" }
end

Rails.application.configure do

  def gettid
    syscall 186 # NOTE: Linux-specific, not portable
  end

  config.log_tags = [
    lambda { |request| "origin=#{request.ip}" },
    lambda { |request| "request_id=#{request.uuid}" }
  ]

  config.log_tags << proc { "tid=#{gettid}" }

end

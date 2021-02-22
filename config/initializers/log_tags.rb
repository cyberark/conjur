Rails.application.configure do

  def gettid
	Time.now.to_i 
  end

  config.log_tags = [
    lambda { |request| "origin=#{request.ip}" },
    lambda { |request| "request_id=#{request.uuid}" }
  ]

  config.log_tags << proc { "tid=#{gettid}" }

end

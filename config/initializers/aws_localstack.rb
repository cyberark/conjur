if Rails.env.development? || Rails.env.test?
  Aws.config.update(
    endpoint: 'http://localstack:4566',
    access_key_id: 'test',
    secret_access_key: 'test',
    region: 'us-east-1'
  )
  if Rails.env.development?
    topic_name = ENV["TOPIC_NAME"]
    puts "Creating SNS topic with name: #{topic_name}"
    sns = Aws::SNS::Client.new
    response = sns.create_topic(
      name: topic_name,
      attributes: {
        'FifoTopic' => 'true',
        'ContentBasedDeduplication' => 'true'
      }
    )
    puts "Created SNS topic with ARN: #{response.topic_arn}"
  end
end

if Rails.env.development? || Rails.env.test?
  Aws.config.update(
    endpoint: 'http://localstack:4566',
    access_key_id: 'test',
    secret_access_key: 'test',
    region: 'us-east-1'
  )
end

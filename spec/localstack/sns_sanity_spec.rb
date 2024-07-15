require 'spec_helper'
require 'aws-sdk-sns'

describe "Sanity for localstack service" do
  let(:sns_object) { Aws::SNS::Client.new }

  before(:each) do
    create_sns_topic
  end

  it 'sanity check for localstack service' do
    # Create SNS topic
    response = sns_object.create_topic(name: 'sanity-check-topic')
    topic_arn = response.topic_arn
    expect(topic_arn).to_not be_nil

    # Publish a message to the SNS topic
    message = 'Hello, LocalStack!'
    publish_response = sns_object.publish(topic_arn: topic_arn, message: message)
    expect(publish_response.message_id).to_not be_nil
  end

  it 'sanity check - using mock SNS topic and publishes a message' do
    # verify the exist SNS topic
    topic_arn = ENV['TOPIC_ARN']
    expect(topic_arn).to_not be_nil

    # Publish a message to the SNS topic
    message = 'Hello, LocalStack!'
    publish_response = sns_object.publish(topic_arn: topic_arn, message: message)
    expect(publish_response.message_id).to_not be_nil
  end
end

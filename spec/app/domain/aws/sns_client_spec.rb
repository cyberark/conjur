require 'spec_helper'
require 'aws-sdk-sns'
require 'aws-sdk-sqs'
require 'json'

RSpec.describe('aws::SnsClient') do
  let(:message) { 'Test message 123#$%^&' }
  let(:message_attributes) { { 'key' => { data_type: 'String', string_value: 'value1234' } } }
  let(:sns_client_instance) { SnsClient.instance }

  before(:each) do
    create_sns_topic
  end

  after(:each) do
    delete_sns_topic
  end

  context 'when publish is successful' do
    it 'returns a successful PublishResponse with a non-empty message_id' do
      response = sns_client_instance.publish(message, message_attributes)
      expect(response.data).to be_a(Aws::SNS::Types::PublishResponse)
      expect(response.message_id).not_to be_empty
    end
  end

  context 'when publish raises an UnauthorizedOperation error' do
    it 'raises UnauthorizedSnsRoleCreds after retry' do
      allow(sns_client_instance.instance_variable_get(:@sns_client)).to receive(:publish).and_raise(Aws::SNS::Errors::UnauthorizedOperation.new(nil, 'UnauthorizedOperation error'))
      expect { sns_client_instance.publish(message, message_attributes) }.to raise_error(Errors::Authentication::Security::UnauthorizedSnsRoleCreds)
    end
  end

  context 'when publish raises an UnauthorizedOperation error on the first attempt and succeeds on the second attempt' do
    it 'succeeds on retry' do
      allow(sns_client_instance.instance_variable_get(:@sns_client)).to receive(:publish).and_raise(Aws::SNS::Errors::UnauthorizedOperation.new(nil, 'UnauthorizedOperation error')).once
      allow(sns_client_instance.instance_variable_get(:@sns_client)).to receive(:publish).and_call_original

      response = sns_client_instance.publish(message, message_attributes)
      expect(response.data).to be_a(Aws::SNS::Types::PublishResponse)
    end
  end

  context 'when publish raises a generic StandardError' do
    it 'raises the StandardError' do
      allow(sns_client_instance.instance_variable_get(:@sns_client)).to receive(:publish).and_raise(StandardError.new('Something went wrong'))

      expect { sns_client_instance.publish(message, message_attributes) }.to raise_error(StandardError)
    end
  end

  context 'when publishing a message to SNS topic' do
    let(:sqs_client) { Aws::SQS::Client.new }
    let(:queue_arn) do
      create_sqs_queue
    end

    before(:each) do
      sns_client_instance.sns_client.subscribe(topic_arn: ENV['TOPIC_ARN'], protocol: 'sqs', endpoint: queue_arn)
    end

    after(:each) do
      delete_sqs_queue
    end

    it 'ensures the message published to SNS topic is received by SQS subscriber' do
      sns_client_instance.publish(message, message_attributes)

      received_message = nil
      Timeout.timeout(10) do
        loop do
          messages = sqs_client.receive_message(queue_url: ENV['QUEUE_URL'], max_number_of_messages: 1).messages
          unless messages.empty?
            received_message = messages.first.body
            break
          end
          sleep 1
        end
      end

      parsed_message = JSON.parse(received_message)
      expect(parsed_message['Message']).to eq(message)
    end
  end
end

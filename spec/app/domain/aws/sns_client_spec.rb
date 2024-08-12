# spec/app/domain/aws/sns_client_spec.rb
require 'spec_helper'
require 'aws-sdk-sns'
require 'aws-sdk-sqs'
require 'json'
require 'thread'

RSpec.describe('aws::SnsClient') do
  let(:message) { 'Test message 123#$%^&' }
  let(:message_attributes) { { 'key' => { data_type: 'String', string_value: 'value1234' } } }
  let(:sns_client_instance) { SnsClient.instance }

  before(:each) do
    create_sns_topic
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('TENANT_ID').and_return('mytenant')
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

  context 'when publish always raises Authentication::Security::UnauthorizedSnsRoleCreds' do
    it 'raises Authentication::Security::UnauthorizedSnsRoleCreds every time publish is called' do
      allow(sns_client_instance.instance_variable_get(:@sns_client)).to receive(:publish).and_raise(Errors::Authentication::Security::UnauthorizedSnsRoleCreds)
      expect { sns_client_instance.publish(message, message_attributes) }.to raise_error(Errors::Authentication::Security::UnauthorizedSnsRoleCreds)
    end
  end

  context 'when credentials are expired' do
    it 'retries with new credentials and publishes successfully' do
      expired_credentials = double('Credentials', access_key_id: 'key', secret_access_key: 'secret', session_token: 'token', expiration: Time.now - 3600)
      valid_credentials = double('Credentials', access_key_id: 'key', secret_access_key: 'secret', session_token: 'token', expiration: Time.now + 3600)

      # Mock assume_role to return expired credentials first, then valid credentials
      allow_any_instance_of(Aws::STS::Client).to receive(:assume_role).and_return(
        double('AssumeRoleResponse', credentials: expired_credentials),
        double('AssumeRoleResponse', credentials: valid_credentials)
      )

      response = sns_client_instance.publish(message, message_attributes)
      expect(response.data).to be_a(Aws::SNS::Types::PublishResponse)
      expect(response.message_id).not_to be_empty
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

  context 'when multiple threads call assume_role' do
    it 'ensures synchronization works correctly' do
      threads = []
      credentials = []

      allow(sns_client_instance).to receive(:credentials_valid?).and_return(false, true)
      # Track the number of times assume_role is called
      expect_any_instance_of(Aws::STS::Client).to receive(:assume_role).once.and_call_original

      10.times do
        threads << Thread.new do
          sns_client_instance.send(:assume_role)
          credentials << sns_client_instance.instance_variable_get(:@credentials)
        end
      end

      threads.each(&:join)

      # Ensure all threads received the same credentials object - because the creds updated only once for the first call
      expect(credentials.uniq.size).to eq(1)
    end
  end

end

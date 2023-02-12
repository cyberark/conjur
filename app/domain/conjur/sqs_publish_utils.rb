require 'securerandom'
require 'aws-sdk-sqs'
require 'aws-sdk-sts'

module Conjur
  class SqsPublishUtils

    $region = 'us-east-2'
    $transaction_id = 0
    @@sqs_client = Aws::SQS::Client.new(region: $region, verify_checksums: false)
    @transaction_message="{ \"entities\": [ "

    def initialize()
      Rails.logger.info("++++++++++ initialize 1")
      @transaction_message="{ \"entities\": [ "
    end

    def add_to_message entity_message
      @transaction_message = @transaction_message + entity_message + ","
    end

    def send_message #transaction_message
        $message_id = rand(1..100000)

        region = 'us-east-2'
        queue_name = 'OfiraConjurEdgeQueue.fifo'
        #message_body = 'This is my message.'
        Rails.logger.info("+++++++++ publish_changes 4")
        #sts_client = Aws::STS::Client.new(region: region)
        # For example:
        # 'https://sqs.us-east-1.amazonaws.com/111111111111/my-queue'
        queue_url = 'https://sqs.' + region + '.amazonaws.com/' +
          '238637036211' + '/' + queue_name

        @transaction_message = @transaction_message + "{\"end\": " + $message_id.to_s + "} ] }"

        Rails.logger.info("+++++++++ publish_changes 5 transaction_message = #{@transaction_message}")

        #if ENV['SQS_FIFO_NAME'].present?
          Rails.logger.info("+++++++++ Sending a message to the queue named '#{queue_name}'...")

          resp1 = @@sqs_client.send_message(
                queue_url: queue_url,
                message_body: @transaction_message, # "transaction_message" + $message_id.to_s,
                message_group_id: 'message_group_id')
          Rails.logger.info("+++++++++ publish 5.1 resp1 = #{resp1}, message_id =#{$message_id}")
          Rails.logger.info("+++++++++ Sending a message to the queue named '#{queue_name}'...")
        #end
        Rails.logger.info("+++++++++ publish_changes 7")
        @transaction_message = ""
    end
  end
end

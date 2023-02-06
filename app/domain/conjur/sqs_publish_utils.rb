require 'securerandom'
require 'aws-sdk-sqs'
require 'aws-sdk-sts'

module Conjur
  class SqsPublishUtils


    $region = 'us-east-2'
    $sqs_client = Aws::SQS::Client.new(region: $region, verify_checksums: false)
    $message_id=0

    def send_message transaction_message
        $message_id = rand(1..100000)

        region = 'us-east-2'
        queue_name = 'OfiraConjurEdgeQueue.fifo'
        #message_body = 'This is my message.'
        Rails.logger.info("+++++++++ publish_changes 4")
        #sts_client = Aws::STS::Client.new(region: region)
        Rails.logger.info("+++++++++ publish_changes 5 transaction_message = #{transaction_message}")
        # For example:
        # 'https://sqs.us-east-1.amazonaws.com/111111111111/my-queue'
        queue_url = 'https://sqs.' + region + '.amazonaws.com/' +
          '238637036211' + '/' + queue_name

        Rails.logger.info("+++++++++ Sending a message to the queue named '#{queue_name}'...")

        resp1 = $sqs_client.send_message(
              queue_url: queue_url,
              message_body: transaction_message, # "transaction_message" + $message_id.to_s,
              message_group_id: 'message_group_id')
        Rails.logger.info("+++++++++ publish 5.1 resp1 = #{resp1}, message_id =#{$message_id}")
        Rails.logger.info("+++++++++ Sending a message to the queue named '#{queue_name}'...")
        Rails.logger.info("+++++++++ publish_changes 7")
    end
  end
end

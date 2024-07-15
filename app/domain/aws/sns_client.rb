# app/domain/aws/sns_client.rb
require 'singleton'
require 'aws-sdk-sns'

class SnsClient
  include Singleton

  def initialize
    @sns_client = Aws::SNS::Client.new
  end

  def publish(message, message_attributes)
    publish_message_and_error_handle(message, message_attributes)
  end

  def sns_client
    @sns_client
  end

  private

  def publish_message_and_error_handle(message, message_attributes, should_retry: false)
    begin
      response = @sns_client.publish({
        topic_arn: get_topic_arn,
        message: message,
        message_attributes: message_attributes,
        message_group_id: get_tenant_id,
      })
      return response

    rescue Aws::SNS::Errors::UnauthorizedOperation => e
      handle_unauthorized_operation(e, message, message_attributes, should_retry)
    rescue StandardError => e
      Rails.logger.error("Failed to publish message: #{e.message}")
      raise e
    end
  end

  def handle_unauthorized_operation(exception, message, message_attributes, should_retry)
    should_retry ? handle_failed_retry(exception) : attempt_retry(exception, message, message_attributes)
  end

  def handle_failed_retry(exception)
    Rails.logger.error("Failed to publish message after retry: #{exception.message}")
    raise Errors::Authentication::Security::UnauthorizedSnsRoleCreds
  end

  def attempt_retry(exception, message, message_attributes)
    Rails.logger.error("UnauthorizedOperation error, attempting to assume role and retry: #{exception.message}")
    # assume_role
    publish_message_and_error_handle(message, message_attributes, should_retry: true)
  end

  def get_tenant_id
    ENV['TENANT_ID']
  end

  def get_topic_arn
    ENV['TOPIC_ARN']
  end
end
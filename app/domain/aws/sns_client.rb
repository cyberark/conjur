# app/domain/aws/sns_client.rb
require 'singleton'
require 'aws-sdk-sns'
require 'aws-sdk-sts'
require 'thread'  # For Mutex

class SnsClient
  include Singleton

  def self.reset_instance
    Singleton.__init__(self)
  end

  def initialize( duration_seconds: 900)
    @mutex = Mutex.new
    @duration_seconds = duration_seconds  # 15 minutes by default
    @credentials = assume_role
    @sns_client = create_sns_client(@credentials)
  end

  def publish(message, message_attributes)
    publish_message_with_error_handling(message, message_attributes)
  end

  def sns_client
    @sns_client
  end

  private

  def publish_message_with_error_handling(message, message_attributes, second_try_to_publish: false)
    unless credentials_valid?
      handle_unauthorized_operation(message, message_attributes, second_try_to_publish)
    end
    Rails.logger.debug{"Publishing message to SNS topic."}
    @sns_client.publish(
      topic_arn: fetch_topic_arn,
      message: message,
      message_attributes: message_attributes,
      message_group_id: fetch_tenant_id
    )
  rescue => e
    if credentials_valid?
      Rails.logger.error("Failed to publish message: #{e.message}")
      raise e
    else
      handle_unauthorized_operation(message, message_attributes, second_try_to_publish)
    end
  end

  def handle_unauthorized_operation( message, message_attributes, second_try_to_publish)
    if second_try_to_publish
      handle_failed_retry
    else
      # first try to publish - so we will try one more time to assume and publish msg
      Rails.logger.debug{"Credentials expired, attempting to assume role and retry."}
      assume_role
      @sns_client = create_sns_client(@credentials)
      publish_message_with_error_handling(message, message_attributes, second_try_to_publish: true)
    end
  end

  def handle_failed_retry
    Rails.logger.error("Failed to publish message after retry attempt.")
    raise Errors::Authentication::Security::UnauthorizedSnsRoleCreds
  end

  def assume_role
    @mutex.synchronize do
      return @credentials if credentials_valid?
      Rails.logger.debug{"Assuming role to publish message to SNS topic."}
      tenant_id_tag = fetch_tenant_id.gsub('-', '')
      tags = [{ key: 'tenant_id', value: "#{tenant_id_tag}" }]
      sts_client = Aws::STS::Client.new
      resp = sts_client.assume_role(
        role_arn: fetch_role_arn,
        role_session_name: "PublishSNSMessageSession",
        tags: tags,
        duration_seconds: @duration_seconds
      )
      @credentials = resp.credentials
    end
  end

  def credentials_valid?
    @credentials && @credentials.expiration > Time.now
  end

  def create_sns_client(credentials)
     Aws::SNS::Client.new(
      region: fetch_tenant_region,
      access_key_id: credentials.access_key_id,
      secret_access_key: credentials.secret_access_key,
      session_token: credentials.session_token
    )
  end



  def fetch_tenant_id
    Rails.application.config.conjur_config.tenant_id { raise "TENANT_ID not set in environment variables" }
  end

  def fetch_topic_arn
    Rails.application.config.conjur_config.try(:conjur_pubsub_sns_topic) { raise "conjur_pubsub_sns_topic not set in config" }
  end

  def fetch_tenant_region
    Rails.application.config.conjur_config.tenant_region { raise "TENANT_REGION not set in environment variables" }
  end

  def fetch_role_arn
    Rails.application.config.conjur_config.try(:conjur_pubsub_iam_role) { raise "conjur_pubsub_iam_role not set in config" }
  end
end
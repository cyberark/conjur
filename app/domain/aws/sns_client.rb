# app/domain/aws/sns_client.rb
require 'singleton'
require 'aws-sdk-sns'
require 'aws-sdk-sts'
require 'thread'  # For Mutex

class SnsClient
  include Singleton

  def initialize
    @mutex = Mutex.new
    @region = fetch_tenant_region
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
    response = @sns_client.publish(
      topic_arn: fetch_topic_arn,
      message: message,
      message_attributes: message_attributes,
      message_group_id: fetch_tenant_id
    )
    response
  rescue Aws::SNS::Errors::UnauthorizedOperation => e
    handle_unauthorized_operation(e, message, message_attributes, second_try_to_publish)
  rescue StandardError => e
    Rails.logger.error("Failed to publish message: #{e.message}")
    raise e
  end

  def handle_unauthorized_operation(exception, message, message_attributes, second_try_to_publish)
    if second_try_to_publish
      handle_failed_retry(exception)
    else
      # first try to publish - so we will try one more time to assume and publish msg
      Rails.logger.error("UnauthorizedOperation error, attempting to assume role and retry: #{exception.message}")
      @credentials = assume_role
      @sns_client = create_sns_client(@credentials)
      publish_message_with_error_handling(message, message_attributes, second_try_to_publish: true)
    end
  end

  def handle_failed_retry(exception)
    Rails.logger.error("Failed to publish message after retry: #{exception.message}")
    raise Errors::Authentication::Security::UnauthorizedSnsRoleCreds
  end

  def assume_role
    @mutex.synchronize do
      return @credentials if credentials_valid?
      role_arn = fetch_role_arn
      tenant_id_tag = fetch_tenant_id.gsub('-', '')
      tags = [{ key: 'tenant_id', value: "#{tenant_id_tag}" }]
      sts_client = Aws::STS::Client.new
      resp = sts_client.assume_role(
        role_arn: role_arn,
        role_session_name: "PublishSNSMessageSession",
        tags: tags
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
    ENV['TENANT_ID'] { raise "TENANT_ID not set in environment variables" }
  end

  def fetch_topic_arn
    ENV['TOPIC_ARN'] { raise "TOPIC_ARN not set in environment variables" }
  end

  def fetch_tenant_region
    ENV['TENANT_REGION'] { raise "TENANT_REGION not set in environment variables" }
  end

  def fetch_role_arn
    ENV['ROLE_ARN_SNS'] { raise "ROLE_ARN not set in environment variables" }
  end
end
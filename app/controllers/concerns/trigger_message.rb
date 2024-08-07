module TriggerMessage
  extend ActiveSupport::Concern

  def trigger_message_job
    if ENV['ENABLE_PUBSUB'] == 'true'
      Thread.new do
        begin
          logger.debug("Starting MessageJob")
          MessageJob.instance.run
          logger.debug("Finished MessageJob")
        rescue Exception => e
          logger.error("Failed message job: #{e.message}")
        end
      end
    end
  end
end
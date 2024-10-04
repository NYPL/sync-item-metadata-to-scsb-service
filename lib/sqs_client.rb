require 'aws-sdk-sqs'

require_relative './kms_client'

class SqsClient
  def initialize
    begin
      @sqs_queue_url = KmsClient.new.decrypt ENV['SQS_QUEUE_URL']
    rescue Exception => e
      $logger.error "KMS error: #{e.message}"
      raise e
    end

    # Strip rogue whitespace from encrypted value:
    @sqs_queue_url.strip!

    # Extract SQS endpoint (protocol + FQDN) from URL:
    @sqs_queue_endpoint = @sqs_queue_url.match(/https?:\/\/[^\/]+/)[0]
    # Extract SQS queue name from URL:
    @sqs_queue_name = @sqs_queue_url.match(/[\w-]+$/)[0]

    if ENV['AWS_ACCESS_KEY_ID']
      @sqs = Aws::SQS::Client.new(
        region: 'us-east-1',
        access_key_id:  ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
        endpoint: @sqs_queue_endpoint
      )
    else
      @sqs = Aws::SQS::Client.new(
        region: 'us-east-1',
        endpoint: @sqs_queue_endpoint
      )
    end
  end

  def send_message(entries)
    begin
      @sqs.send_message_batch({
        queue_url: @sqs_queue_url,
        entries: entries,
      })
    rescue Exception => e
      $logger.error "SqsClient error: #{e.message}"
      raise e
    end
  end

  def create_queue
    @sqs.create_queue({
      queue_name: @sqs_queue_name
    })
  end
end

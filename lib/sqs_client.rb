require 'aws-sdk-sqs'
require 'lib/kms_client'

class SqsClient
  def initialize
    @sqs_queue_url = KmsClient.new.decrypt ENV['SQS_QUEUE_URL']

    # Strip rogue whitespace from encrypted value:
    @sqs_queue_url.strip!

    # Extract SQS endpoint (protocol + FQDN) from URL:
    @sqs_queue_endpoint = @sqs_queue_url.match(/https?:\/\/[^\/]+/)[0]
    # Extract SQS queue name from URL:
    @sqs_queue_name = @sqs_queue_url.match(/[\w-]+$/)[0]

    @sqs = Aws::SQS::Client.new(
      region: 'us-east-1',
      endpoint: @sqs_queue_endpoint
    )   
  end 

  def send_message(entries)
    resp = @sqs.send_message_batch({
      queue_url: @sqs_queue_url,
      entries: entries,
    })  
    resp
  end 

  def create_queue
    @sqs.create_queue({
      queue_name: @sqs_queue_name
    })  
  end 
end

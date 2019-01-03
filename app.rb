require 'lib/message'
require 'lib/errors'

def handle_event(event:, context:)
  begin
    validate_request event

    message = prepare_message event['queryStringParameters']
    
    # Push to queue:
    response = message.send_update_message_to_sqs.to_h

    respond 200, { success: true, result: response.to_h }

  rescue ParameterError => e
    respond 400, message: e.message

  rescue => e
    respond 500, message: e.message
  end
end

def prepare_message(params)
  barcodes = params['barcodes'].strip.split(/[\W\s]+/)
  user_email = params['user_email'].strip

  # Create message instance
  message = Message.new(barcodes: barcodes, protect_cgd: params[:protect_cgd], action: 'update', user_email: user_email)

  raise ParameterError.new("Message validation failed") if message.valid?

  message
end

def validate_request(event)
  raise "Invalid request" if event["path"] != "/api/v0.1/recap/sync-item-metadata-to-scsb"

  raise ParameterError.new("No parameters given") if event['queryStringParameters'].blank?

  # Parse request params
  params = event['queryStringParameters']

  raise ParameterError.new("Missing barcodes parameter") if params['barcodes'].blank?
  raise ParameterError.new("Missing user_email parameter") if params['user_email'].blank?
end

def respond(statusCode = 200, body = nil)
  { statusCode: statusCode, body: body.to_json, headers: { "Content-type": "application/json" } }
end

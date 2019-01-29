require 'base64'

require_relative 'lib/message'
require_relative 'lib/errors'
require_relative 'lib/custom_logger'

# Main handler:
def handle_event(event:, context:)
  path = event["path"]
  method = event["httpMethod"].downcase

  if method == 'post' && path == "/api/v0.1/recap/sync-item-metadata-to-scsb"
    return handle_sync_item_metadata_to_scsb event
  elsif method == 'get' && path == "/docs/sync-item-metadata-to-scsb"
    return handle_swagger
  else
    raise "Invalid request"
  end
end

def handle_swagger
  $swagger_doc = JSON.parse File.read('swagger.json') if $swagger_doc.nil?

  respond 200, $swagger_doc
end

def handle_sync_item_metadata_to_scsb (event)
  begin
    params = parse_params event

    message = prepare_message params
    
    # Push to queue:
    response = message.send_message_to_sqs.to_h

    CustomLogger.info "Sent barcodes to SQS", params

    respond 200, { success: true, result: response.to_h }

  rescue ParameterError => e
    respond 400, message: "ParameterError: #{e.message}"

  rescue => e
    respond 500, message: e.message
  end
end

def prepare_message(params)
  CustomLogger.debug "Preparing message", params

  barcodes = params['barcodes']
  user_email = params['user_email'].strip
  action = params['action'] || 'update'
  source = params['source']

  # Create message instance
  message = Message.new(barcodes: barcodes, protect_cgd: params['protect_cgd'], action: action, user_email: user_email, bib_record_number: params['bib_record_number'], source: source)

  raise ParameterError.new("Message validation failed: #{message.errors.full_messages}") if ! message.valid?
  CustomLogger.debug "Prepared message", message

  message
end

def parse_params (event)
  CustomLogger.debug("Parsing params", event['body'])

  raise ParameterError.new("No parameters given") if event['body'].blank?

  # Parse body
  params = event['body']
  params = Base64.decode64 params if event['isBase64Encoded']
  begin
    params = JSON.parse params
  rescue Exception => e
    raise ParameterError.new("Error parsing JSON body: #{e.message}")
  end

  raise ParameterError.new("Missing barcodes parameter") if params['barcodes'].blank?
  raise ParameterError.new("Barcodes parameter must be an array. #{params['barcodes'].class} given.") if ! params['barcodes'].is_a?(Array)
  params['barcodes'] = params['barcodes'].map(&:strip).select { |b| b.strip.match /\w+/ }
  raise ParameterError.new("No valid barcodes given") if params['barcodes'].empty?
  raise ParameterError.new("Missing user_email parameter") if params['user_email'].blank?
  raise ParameterError.new("Invalid action") if ! params['action'].blank? && !['update', 'transfer'].include?(params['action'])
  raise ParameterError.new("Missing bib_record_number for transfer") if params['action'] == 'transfer' && params['bib_record_number'].blank?
  params['protect_cgd'] = params['protect_cgd'] || false
  raise ParameterError.new("Invalid source") if params['source'].present? && !['bib-item-store-update', 'scsbuster', ''].include?(params['source'])

  CustomLogger.debug("Parsed params", params)

  params
end

def respond(statusCode = 200, body = nil)
  CustomLogger.debug("Responding with #{statusCode}", body)
  { statusCode: statusCode, body: body.to_json, headers: { "Content-type": "application/json" } }
end

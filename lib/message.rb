require 'active_model'

require_relative './sqs_client'

class Message
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Model
  attr_accessor :barcodes, :user_email, :protect_cgd, :action, :bib_record_number, :source

  validate :barcode_format, :bib_record_number_format

  def valid_barcodes
    if barcodes && barcodes.is_a?(Array)
      barcodes.map!(&:to_s)
      barcodes.select{ |b| b[/^\d{14}$/] }
    else
      []
    end
  end

  def invalid_barcodes
    invalid = []
    if barcodes && barcodes.is_a?(Array)
      invalid = barcodes
      invalid = invalid - valid_barcodes
    end
    return invalid
  end

  def prepare_message_for_sqs
    message_body = {
      barcodes: self.barcodes,
      protectCGD: self.protect_cgd,
      action: self.action,
      user_email: self.user_email,
      source: self.source
    }
    message_body['bibRecordNumber'] = self.bib_record_number if self.action == 'transfer'

    entry = {
      id: self.barcodes.first,
      message_body: JSON.generate(message_body)
    }
  end

  def send_message_to_sqs
    sqs = SqsClient.new
    entry = prepare_message_for_sqs

    $logger.debug "Sending message", entry
    sqs.send_message([entry])
  end

  private

  def bib_record_number_format
    return if action != 'transfer'
    errors.add(:bib_record_number, "Bib record number is blank.") if self.bib_record_number.blank? && self.action == 'transfer'
    errors.add(:bib_record_number, "The bib record number must be 10 characters long and start with \"b\". Example: b12345678x.") if self.bib_record_number.present? && self.action == 'transfer' && !self.bib_record_number.match?(/^[b]\d{8}[x|\d]$/)
  end

  def barcode_format
    if barcodes.blank?
      errors.add(:barcodes, "No barcodes present.")
    end
    if !barcodes.is_a?(Array)
      errors.add(:barcodes, "Barcodes not an array.")
    end
    if invalid_barcodes.count > 0
      errors.add(:barcodes, "Barcode(s) must be 14 numerical digits in length.")
    end
  end
end

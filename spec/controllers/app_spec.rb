require 'spec_helper'

require_relative '../../app'

describe 'app', :type => :controller do
  before do
    $logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
  end

  describe '#parse_params' do
    it 'throws error if barcodes missing/invalid' do
      expect { parse_params({ 'body' => {}.to_json }) }.to raise_error(ParameterError)
      expect { parse_params({ 'body' => { 'user_email' => 'user@example.com', 'barcodes' => '' }.to_json }) }.to raise_error(ParameterError)
      expect { parse_params({ 'body' => { 'user_email' => 'user@example.com', 'barcodes' => [''] }.to_json }) }.to raise_error(ParameterError)

      # This will be interpretted as barcodes => ['1']
      expect { parse_params({ 'body' => { 'user_email' => 'user@example.com', 'barcodes' => ['1 ', ''] }.to_json }) }.to_not raise_error
    end

    it 'cast protect_cgd to bool' do
      expect(parse_params({ 'body' => { 'protect_cgd' => nil, 'user_email' => 'user@example.com', 'barcodes' => ['1'] }.to_json })['protect_cgd']).to eq(false)
      expect(parse_params({ 'body' => { 'protect_cgd' => false, 'user_email' => 'user@example.com', 'barcodes' => ['1'] }.to_json })['protect_cgd']).to eq(false)
      expect(parse_params({ 'body' => { 'protect_cgd' => true, 'user_email' => 'user@example.com', 'barcodes' => ['1'] }.to_json })['protect_cgd']).to eq(true)
    end

    it 'throws error if source invalid' do
      expect { parse_params({ 'body' => { 'protect_cgd' => true, 'user_email' => 'user@example.com', 'barcodes' => ['1'], 'source' => 'fladeedle' }.to_json }) }.to raise_error(ParameterError)
    end
  end

  describe '#prepare_message' do
    it 'builds update message based on params' do
      message = prepare_message({ 'user_email' => 'user@example.com', 'barcodes' => ['1' * 14] })
      expect(message).to be_a(Message)
      expect(message.barcodes).to be_a(Array)
      expect(message.action).to eq('update')
      expect(message.user_email).to eq('user@example.com')
      # protect_cgd is a boolean, but nil is a fine stand-in for false
      expect(message.protect_cgd).to eq(nil)
      expect(message.bib_record_number).to eq(nil)
    end

    it 'builds transfer message based on params' do
      # Must match: /^[b]\d{8}[x|\d]$/
      bnum = "b#{'1' * 9}"
      message = prepare_message({ 'user_email' => 'user@example.com', 'barcodes' => ['1' * 14], 'action' => 'transfer', 'bib_record_number' => bnum, 'source' => 'bib-item-store-update' })
      expect(message).to be_a(Message)
      expect(message.barcodes).to be_a(Array)
      expect(message.action).to eq('transfer')
      expect(message.user_email).to eq('user@example.com')
      expect(message.bib_record_number).to eq(bnum)
      expect(message.source).to eq('bib-item-store-update')
    end

    it 'throws error if transfer missing bib/invalid number' do
      expect { prepare_message({ 'user_email' => 'user@example.com', 'barcodes' => ['1' * 14], 'action' => 'transfer' }) }.to raise_error(ParameterError)
      expect { prepare_message({ 'user_email' => 'user@example.com', 'barcodes' => ['1' * 14], 'action' => 'transfer', 'bib_record_number' => '' }) }.to raise_error(ParameterError)
      # Must match: /^[b]\d{8}[x|\d]$/
      expect { prepare_message({ 'user_email' => 'user@example.com', 'barcodes' => ['1' * 14], 'action' => 'transfer', 'bib_record_number' => "b#{'1' * 8}" }) }.to raise_error(ParameterError)
      expect { prepare_message({ 'user_email' => 'user@example.com', 'barcodes' => ['1' * 14], 'action' => 'transfer', 'bib_record_number' => "b#{'1' * 10}" }) }.to raise_error(ParameterError)
    end

    it 'throws error if Message validation determines barcode invalid' do
      # Barcodes of 13 characters should fail
      expect { prepare_message({ 'user_email' => 'user@example.com', 'barcodes' => ['1' * 13] }) }.to raise_error(ParameterError)
    end
  end
end

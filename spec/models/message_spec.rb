require 'spec_helper'

describe Message do
  #Validations
  it "should validate that barcodes are invalid if they don't fit the format" do
    barcodes_not_array        = Message.new(barcodes: "Garmonbozia")
    barcodes_not_right_length = Message.new(barcodes: ['123', '456', 789])
    
    expect(barcodes_not_array.valid?).to        eq(false)
    expect(barcodes_not_right_length.valid?).to eq(false)
  end
  
  it "should validate that barcodes are present" do
    barcodes_missing            = Message.new
    expect(barcodes_missing.valid?).to  eq(false)
  end
  
  it "should validate the validity of a bib_record_number for transfer messages" do
    # Only required on transfer
    # starts with the letter b 
    # ... followed by 8 numerical digits 
    # ... followed by one character which could be a numerical digit or the letter x
    bib_record_number_valid               = Message.new(barcodes: ['12345678901234'], bib_record_number: 'b12345678x', action: 'transfer')
    bib_record_number_incorrect_start     = Message.new(barcodes: ['12345678901234'], bib_record_number: 'a12345678x', action: 'transfer')
    bib_record_number_not_transfer        = Message.new(barcodes: ['12345678901234'], bib_record_number: 'b12345', action: 'update')
    bib_record_number_valid_2             = Message.new(barcodes: ['12345678901234'], bib_record_number: 'b123456781', action: 'transfer')
    bib_record_number_invalid_check       = Message.new(barcodes: ['12345678901234'], bib_record_number: 'b12345678A', action: 'transfer')
    bib_record_number_too_short           = Message.new(barcodes: ['12345678901234'], bib_record_number: 'b1234567x', action: 'transfer')
    bib_record_number_too_long            = Message.new(barcodes: ['12345678901234'], bib_record_number: 'b123456789x', action: 'transfer')
    bib_record_number_missing             = Message.new(barcodes: ['12345678901234'], bib_record_number: nil, action: 'transfer')
    
    expect(bib_record_number_valid.valid?).to               eq(true)
    expect(bib_record_number_incorrect_start.valid?).to     eq(false)
    expect(bib_record_number_not_transfer.valid?).to        eq(true)
    expect(bib_record_number_valid_2.valid?).to             eq(true)
    expect(bib_record_number_invalid_check.valid?).to       eq(false)
    expect(bib_record_number_too_short.valid?).to           eq(false)
    expect(bib_record_number_too_long.valid?).to            eq(false)
    expect(bib_record_number_missing.valid?).to             eq(false)
  end
  
  #Methods
  it "should return an array of all valid or invalid barcodes when asked" do
    mixed_barcodes        = Message.new(barcodes: ['12345678901234',1,2])
    all_bad_barcodes      = Message.new(barcodes: ['123', '456', 789])
    no_barcodes           = Message.new
    all_good_barcodes     = Message.new(barcodes: [12345678901234, 22345678901235, 32345678901236])
    expect(mixed_barcodes.invalid_barcodes).to    eq(['1','2'])
    expect(mixed_barcodes.valid_barcodes).to      eq(['12345678901234'])
    expect(all_bad_barcodes.valid_barcodes).to    eq([])
    expect(all_bad_barcodes.invalid_barcodes).to  eq(['123', '456', '789'])
    expect(all_good_barcodes.valid_barcodes).to   eq(['12345678901234', '22345678901235', '32345678901236'])
    expect(all_good_barcodes.invalid_barcodes).to eq([])
    expect(no_barcodes.valid_barcodes).to         eq([])
    expect(no_barcodes.invalid_barcodes).to       eq([])
  end

  describe '#prepare_message_for_sqs' do
    it 'should prepare a update message' do
      entry = Message.new(barcodes: ['123'], protect_cgd: false, action: 'update', user_email: 'user@example.com').prepare_message_for_sqs
      expect(entry).to be_a(Hash)
      expect(entry[:id]).to eq('123')
      expect(entry[:message_body]).to be_a(String)

      parsed_entry = JSON.parse entry[:message_body]
      expect(parsed_entry).to be_a(Hash)
      expect(parsed_entry['barcodes']).to be_a(Array)
      expect(parsed_entry['barcodes'].first).to eq('123')
      expect(parsed_entry['action']).to eq('update')
      expect(parsed_entry['user_email']).to eq('user@example.com')
    end

    it 'should prepare a transfer message' do
      entry = Message.new(barcodes: ['123'], protect_cgd: false, action: 'transfer', user_email: 'user@example.com', bib_record_number: 'b1234').prepare_message_for_sqs
      expect(entry).to be_a(Hash)
      expect(entry[:id]).to eq('123')
      expect(entry[:message_body]).to be_a(String)

      parsed_entry = JSON.parse entry[:message_body]
      expect(parsed_entry).to be_a(Hash)
      expect(parsed_entry['barcodes']).to be_a(Array)
      expect(parsed_entry['barcodes'].first).to eq('123')
      expect(parsed_entry['action']).to eq('transfer')
      expect(parsed_entry['user_email']).to eq('user@example.com')
      expect(parsed_entry['bibRecordNumber']).to eq('b1234')
    end
  end
end

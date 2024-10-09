require 'aws-sdk-kms'
require 'base64'

class KmsClient
  def initialize
    if ENV['LOCAL']
      @kms = Aws::KMS::Client.new(
        region: 'us-east-1',
        access_key_id:  ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
      )
    else
      @kms = Aws::KMS::Client.new(region: 'us-east-1')
    end
  end

  def decrypt(cipher)
    # Assume value is base64 encoded:
    decoded = Base64.decode64 cipher
    decrypted = @kms.decrypt ciphertext_blob: decoded
    decrypted[:plaintext]
  end
end

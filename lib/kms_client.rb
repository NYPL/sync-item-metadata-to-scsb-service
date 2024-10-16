require 'aws-sdk-kms'
require 'base64'

class KmsClient
  def initialize
    # To work around https://github.com/aws/aws-sam-cli/issues/3118:
    ENV.delete "AWS_SESSION_TOKEN" if ENV['AWS_SESSION_TOKEN'] == ''
    @kms = Aws::KMS::Client.new(region: 'us-east-1') if @kms.nil?
    @kms
  end

  def decrypt(cipher)
    # Assume value is base64 encoded:
    decoded = Base64.decode64 cipher
    decrypted = @kms.decrypt ciphertext_blob: decoded
    decrypted[:plaintext]
  end
end

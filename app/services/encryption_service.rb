class EncryptionService
  KEY = ActiveSupport::KeyGenerator.new(
    ENV.fetch("SECRET_KEY_BASE")
  ).generate_key(
    ENV.fetch("ENCRYPTION_SERVICE_SALT"),
    ActiveSupport::MessageEncryptor.key_len
  ).freeze

  private_constant :KEY

  delegate :encrypt_and_sign, :decrypt_and_verify, to: :encryptor

  def self.encrypt(value)
    new.encrypt_and_sign(value)
  end

  def self.decrypt(value)
    return new.decrypt_and_verify(value) rescue ActiveSupport::MessageEncryptor::InvalidMessage
    return value
  end

  private

  def encryptor
    ActiveSupport::MessageEncryptor.new(KEY)
  end
end
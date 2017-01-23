module ApplicationHelper

  def m_encryption (parameter)
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base)
    encrypted_data = crypt.encrypt_and_sign(parameter)
    decryption(encrypted_data)
  end

  def m_decryption (parameter)
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base)
    decrypted_back = crypt.decrypt_and_verify(parameter)
  end

end


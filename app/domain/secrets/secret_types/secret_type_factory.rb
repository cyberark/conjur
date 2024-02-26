class SecretTypeFactory

  def create_secret_type(type)
    if !type.nil? && type.eql?("static")
      Secrets::SecretTypes::StaticSecretType.new
    elsif !type.nil? && type.eql?("ephemeral")
      Secrets::SecretTypes::EphemeralSecretType.new
    else
      raise ApplicationController::BadRequestWithBody, "Secret type is unsupported"
    end
  end
end


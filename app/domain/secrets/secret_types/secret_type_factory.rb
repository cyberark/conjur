class SecretTypeFactory
  def create_secret_type(type)
    if !type.nil? && type.casecmp("static").zero?
      Secrets::SecretTypes::StaticSecretType.new
    elsif type.casecmp("ephemeral").zero?
      Secrets::SecretTypes::EphemeralSecretType.new
    else
      raise ApplicationController::BadRequestWithBody, "Secret type is unsupported"
    end
  end
end
# frozen_string_literal: true

require_relative './aws_issuer_type'

class IssuerTypeFactory
  def create_issuer_type(type)
    if !type.nil? && type.casecmp("aws").zero?
      AwsIssuerType.new
    else
      raise ApplicationController::BadRequestWithBody, "issuer type is unsupported"
    end
  end
end

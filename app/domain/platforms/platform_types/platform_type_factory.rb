require_relative './aws_platform_type'

class PlatformTypeFactory
  def create_platform_type(type)
    if !type.nil? && type.casecmp("aws").zero?
      AwsPlatformType.new
    else
      raise ApplicationController::BadRequest, "platform type must be aws"
    end
  end
end

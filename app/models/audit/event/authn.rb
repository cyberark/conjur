require 'ostruct'

class Audit::Event::Authn < OpenStruct
  def initialize role:, service:, authenticator_name:
    super
  end

  def emit_success
    self.success = true
    Audit.info message, 'authn', facility: 10, **structured_data
  end

  def emit_failure error_message
    self.error_message = error_message
    self.success = false
    Audit.warn message, 'authn', facility: 10, **structured_data
  end

  def message
    if success?
      format SUCCESS_TEMPLATE, role_id, authenticator_name, service_message_part
    else
      format FAILURE_TEMPLATE, role_id, authenticator_name, service_message_part, error_message
    end
  end

  SUCCESS_TEMPLATE = "%s successfully authenticated with authenticator %s%s".freeze
  FAILURE_TEMPLATE = "%s failed to authenticate with authenticator %s%s: %s".freeze

  def service_message_part
    " service #{service_id}" if service_id
  end

  def success?
    !!success
  end

  SDID = ::Audit::SDID

  def structured_data
    {
      SDID::SUBJECT => { role: role_id },
      SDID::AUTH => auth_sd,
      SDID::ACTION => {
        operation: 'authenticate',
        result: success?? 'success' : 'failure'
      }
    }
  end

  private

  def role_id
    role.id
  end

  def service_id
    service && service.id
  end

  def auth_sd
    { authenticator: authenticator_name }.tap do |result|
      result[:service] = service_id if service_id
    end
  end
end

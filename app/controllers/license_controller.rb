# frozen_string_literal: true

class LicenseController < RestController
  include GroupMembershipValidator
  include StaticAccount
  include AccountValidator

  COMPONENT_NAME = 'Conjur Cloud'
  USER_TYPE = 'Workloads' # The user type is the type of license purchased by the user
  CONTENT_TYPE = 'application/json'

  def show
    StaticAccount.set_account("cucumber")
    allowed_params = %i[language]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("GET /license/conjur#{options[:language]}"))
    json = "" 
    status = :bad_request
    if options[:language] == 'english'
      validate_user_is_in_admin_group
      count = count_workloads_in_use
      json = construct_response(count) 
      status = :ok
    else
      logger.error(LogMessages::Conjur::GeneralError.new("Language #{options[:language]} is not supported"))
      raise Errors::Conjur::ParameterValueInvalid.new("language", "#{options[:language]} is not supported")
    end
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET /license/conjur#{options[:language]}"))
    render(json: json, status: status, content_type: CONTENT_TYPE)
  end

  def count_workloads_in_use
    # The user purchase a license for a specific number of workloads (hosts)
    begin
      options = { account: StaticAccount.account,  kind: 'host', exclude: 'false' }
      scope = Resource.visible_to(Role[current_user.id])
      scope = scope.search(**options)
    rescue ArgumentError => e
      logger.error(LogMessages::Conjur::GeneralError.new(e.message))
      raise ApplicationController::InternalServerError, e.message
    end
    scope.count('*'.lit)
  end

  def validate_user_is_in_admin_group
    account = StaticAccount.account 
    validate_conjur_admin_group(account)
  end

  def construct_response(workloads_in_use)
    <<-RESPONSE 
      {
        "componentName": "#{COMPONENT_NAME}",
        "optionalSummary": {
          "name": "#{USER_TYPE}",
          "used": "#{workloads_in_use}",
        },
        "licenseData": [
          {
            "licenseSubCategory": "Licenses",
            "licenseElements": [
              {
                "name": "#{USER_TYPE}",
                "used": "#{workloads_in_use}",
              }
            ]
          }
        ]
      }
    RESPONSE
  end
end

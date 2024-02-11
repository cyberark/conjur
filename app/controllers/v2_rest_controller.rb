require './app/domain/resources/resources_handler'
class V2RestController < RestController
  include APIValidator
  include ResourcesHandler

  before_action :validate_header
  before_action :current_user
  after_action  :update_response_header

  def update_response_header
    if response.headers['Content-Type'].nil?
      response.headers['Content-Type'] = 'application/x.secretsmgr.v2+json'
    else
      response.headers['Content-Type'] = response.headers['Content-Type'].sub('application/json', 'application/x.secretsmgr.v2+json')
    end
  end
end
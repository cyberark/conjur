class V2RestController < RestController
  before_action :validate_header
  after_action  :update_response_header

  def update_response_header
    if response.headers['Content-Type'].nil?
      response.headers['Content-Type'] = 'application/x.secretsmgr.v2+json'
    else
      response.headers['Content-Type'] = response.headers['Content-Type'].sub('application/json', 'application/x.secretsmgr.v2+json')
    end
  end
end
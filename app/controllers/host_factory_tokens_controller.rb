class HostFactoryTokensController < RestController
  include FindResource
  include AuthorizeResource

  before_filter :find_resource, only: [ :create ]

  def create
    authorize :execute

    expiration = params.delete(:expiration) or raise ArgumentError, "expiration"
    count = (params.delete(:count) || 1).to_i
    cidr = params.delete(:cidr)
    
    options = {
      resource: host_factory,
      expiration: DateTime.iso8601(expiration)
    }
    options[:cidr] = cidr if cidr
    
    tokens = [0..count].map do
      HostFactoryToken.create options
    end
    
    render json: tokens
  end
  
  protected
  
  def host_factory; @resource; end
  
  def resource_id
    params[:host_factory] or raise ArgumentError, "host_factory"
  end
end

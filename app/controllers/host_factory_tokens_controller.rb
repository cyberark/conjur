class HostFactoryTokensController < RestController
  include FindResource
  include AuthorizeResource

  before_filter :find_resource, only: [ :create ]
  before_filter :find_token, only: [ :destroy ]

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
  
  def destroy
    @resource = @token.host_factory
    
    authorize :update
    
    @token.destroy
    
    head 204
  end
  
  protected
  
  def host_factory; @resource; end
  
  def find_token
    @token = HostFactoryToken.from_token(params[:id]) or raise RecordNotFound
  end
  
  def resource_id
    params[:host_factory] or raise ArgumentError, "host_factory"
  end
end

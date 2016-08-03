class SecretsController < RestController
  include FindResource
  include AuthorizeResource
  
  before_filter :current_user
  before_filter :current_role
  before_filter :find_resource
    
  def create
    authorize :update
    
    params.slice!(:value)
    
    raise ArgumentError, "'value' parameter is missing" if params.empty?
    raise ArgumentError, "'value' may not be empty" if params[:value].empty?

    Secret.create resource_id: @resource.id, value: params[:value]
    @resource.enforce_secrets_version_limit
          
    head :created
  end
  
  def show
    authorize :execute
    
    version = params[:version]
    secret = if version.is_a?(String) && version.to_i.to_s == version
      @resource.secrets.find{|s| s.counter == version.to_i}
    elsif version.nil?
      @resource.secrets.last
    else
      raise ArgumentError, "invalid type for parameter 'version'"
    end
    raise IndexError if secret.nil?
    value = secret.value
    
    mime_type = if ( a = @resource.annotations_dataset.select(:value).where(name: 'conjur/mime_type').first )
      a[:value]
    end
    mime_type ||= 'text/plain'

    render text: value, content_type: mime_type
  end
end

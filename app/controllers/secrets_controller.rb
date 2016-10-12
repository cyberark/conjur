class SecretsController < RestController
  include FindResource
  include AuthorizeResource
  
  before_filter :current_user
  before_filter :find_resource
    
  def create
    authorize :update
    
    value = request.raw_post

    raise ArgumentError, "'value' may not be empty" if value.blank?

    Secret.create resource_id: @resource.id, value: value
    @resource.enforce_secrets_version_limit
          
    head :created
  end
  
  def show
    authorize :execute
    
    version = params[:version]
    secret = if version.is_a?(String) && version.to_i.to_s == version
      @resource.secrets.find{|s| s.version == version.to_i}
    elsif version.nil?
      @resource.secrets.last
    else
      raise ArgumentError, "invalid type for parameter 'version'"
    end
    raise Exceptions::RecordNotFound, @resource.id, "Requested version does not exist" if secret.nil?
    value = secret.value
    
    mime_type = if ( a = @resource.annotations_dataset.select(:value).where(name: 'conjur/mime_type').first )
      a[:value]
    end
    mime_type ||= 'application/octet-stream'

    render text: value, content_type: mime_type
  end
end

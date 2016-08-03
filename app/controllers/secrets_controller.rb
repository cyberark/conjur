class SecretsController < RestController
  include FindResource
  
  before_filter :current_user
  before_filter :current_role
  before_filter :find_resource
    
  def create
    authorize :update
    
    params.slice!(:value)
    
    raise ArgumentError, "value parameter is missing" if params.empty?
    raise ArgumentError, "value may not be empty" if params[:value].empty?

    @resource.add_secret value: params[:value]
    @resource.enforce_secrets_version_limit
          
    respond_with(@variable)
  end
  
  def show
    authorize :execute
    
    value = if version = Array(params[:version]).first.to_i
      @resource.secrets.last
    else
      @resource.secrets.find{|s| s.counter == version}
    end
    raise IndexError if value.nil?
    
    mime_type = @resource.annotations.select(:value).where(name: 'conjur/mime_type').first || "text/plain"
    render text: value, content_type: mime_type
  end
end

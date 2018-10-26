# frozen_string_literal: true

class HostFactoriesController < ApplicationController
  include BodyParser

  before_filter :verify_token,  only: :create_host

  # Ask the host factory to create a host.
  # This requires the host factory's token in the Authorization header. 
  def create_host
    id = params.delete(:id)
    raise ArgumentError, "id" if id.blank?

    @host_builder = HostBuilder.new(@host_factory.account, id, @host_factory.role, @host_factory.role.layers, params)
    host, api_key = @host_builder.create_host
    response = host.as_json
    response['api_key'] = api_key
    
    render json: response, status: :created
  end
  
  protected
  
  def verify_token
    token = request.headers['Authorization'] or raise Unauthorized
    if token.to_s[/^Token token="(.*)"/]
      token = $1
    else
      raise Unauthorized
    end
    
    @token = HostFactoryToken.from_token token
    raise Unauthorized unless @token && @token.valid? && @token.valid_origin?(request.ip)
    @host_factory = @token.host_factory
  end
end

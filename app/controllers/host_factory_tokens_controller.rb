# frozen_string_literal: true

class HostFactoryTokensController < RestController
  include BodyParser
  include FindResource
  include AuthorizeResource

  before_action :find_token, only: [ :destroy ]

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

    tokens = []
    begin
      count.times do
        tokens << HostFactoryToken.create(options)
      end
    rescue ArgumentError => e
      raise ApplicationController::UnprocessableEntity, e.message
    end
    render json: tokens
  end

  def destroy
    authorize :update

    @token.destroy

    head 204
  end

  protected

  def host_factory; @resource; end

  def find_token
    id = params[:id]
    @token = HostFactoryToken.from_token(id) or raise RecordNotFound, "*:host_factory_token:#{id}"
    @resource = @token.host_factory
    @resource_id = @resource.id
  end

  def resource_id
    @resource_id ||= \
      params[:host_factory] or raise ArgumentError, "host_factory"
  end
end

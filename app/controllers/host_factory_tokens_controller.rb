# frozen_string_literal: true

class HostFactoryTokensController < RestController
  include BodyParser
  include FindResource
  include AuthorizeResource

  before_action :find_token, only: [ :destroy ]

  def create
    raise(ArgumentError, "Invalid resource kind: #{resource.kind}") unless resource.kind == 'host_factory'

    authorize(:execute)

    (expiration = params.delete(:expiration)) || raise(ArgumentError, "expiration")

    countParam = params.delete(:count) || 1
    count = if countParam.is_a?(Integer) || countParam.is_a?(String)
      Integer(countParam, exception: false)
    end
    raise ArgumentError, "Invalid value for parameter 'count': #{countParam}" unless count&.positive?

    expiration = parse_iso8601(expiration)
    raise(ArgumentError, "Value for parameter expiration must be in the future: #{expiration}") unless expiration > DateTime.now

    cidr = params.delete(:cidr)

    options = {
      resource: host_factory,
      expiration: expiration
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
    render(json: tokens)
  end

  def destroy
    authorize(:update)

    @token.destroy

    head(204)
  end

  protected

  def host_factory; @resource; end

  def find_token
    id = params[:id]
    (@token = HostFactoryToken.from_token(id)) || raise(RecordNotFound, "*:host_factory_token:#{id}")
    @resource = @token.host_factory
    @resource_id = @resource.id
  end

  def resource_id
    (@resource_id ||= \
       params[:host_factory]) || raise(ArgumentError, "host_factory")
  end

  def parse_iso8601(str)
    DateTime.iso8601(str)
  rescue
    raise(ArgumentError, "Input is invalid ISO8601 datetime string: #{str}")
  end
end

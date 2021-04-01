# frozen_string_literal: true

# This controller is responsible for creating host records using
# host factory tokens for authorization.
class HostFactoriesController < ApplicationController
  include BodyParser

  before_action :validate_token

  # Ask the host factory to create a host.
  # This requires the host factory's token in the Authorization header.
  def create_host
    host, api_key = do_create_host
    response = host.as_json
    response['api_key'] = api_key

    render(json: response, status: :created)
  end

  protected

  def do_create_host
    host_factory = hf_token.host_factory
    role = host_factory.role
    HostBuilder.new(
      host_factory.account,
      params.require(:id),
      role,
      role.layers,
      params.except(:id)
    ).create_host
  end

  # Note that while all three of the methods below raise plain Unauthorized on
  # an error, these are in fact different errors (missing token, token not
  # found, token expired or wrong origin), it's just we choose to make them
  # indistinguishable to the client.
  # Please resist the temptation to roll them all into one conditional.

  def validate_token
    raise Unauthorized unless hf_token.valid?(origin: request.ip)
  end

  def hf_token
    (@hf_token ||= HostFactoryToken.from_token(auth_token)) || raise(Unauthorized)
  end

  def auth_token
    request.headers['Authorization'].to_s[/^Token token="(.*)"/, 1] \
      || raise(Unauthorized)
  end
end

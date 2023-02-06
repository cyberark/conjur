# frozen_string_literal: true

require 'base64'
require 'json'

class PolicyFactoriesController < RestController
  include AuthorizeResource

  before_action :current_user

  def create
    factory_resource = load_factory(kind: params[:kind], id: params[:id], account: params[:account])
    authorize(:execute, factory_resource)

    Factory::CreateFromPolicyFactory.new.call(
      account: params[:account],
      factory_template: JSON.parse(Base64.decode64(factory_resource.secret.value)),
      request_body: JSON.parse(request.body.read),
      authorization: request.headers["Authorization"]
    )
  end

  def info
    factory_resource = load_factory(kind: params[:kind], id: params[:id], account: params[:account])
    authorize(:execute, factory_resource)

    template = JSON.parse(Base64.decode64(factory_resource.secret.value))
    render(json: template['schema'])
  end

  private

  def load_factory(kind:, id:, account:)
    Resource["#{account}:variable:conjur/factories/#{kind}/#{id}"]
  end

end

# frozen_string_literal: true

require 'base64'
require 'json'
require './app/domain/responses'

class PolicyFactoriesController < RestController
  before_action :current_user

  def create
    response = load_factory(kind: params[:kind], id: params[:id], account: params[:account])
      .bind do |factory|
        Factory::CreateFromPolicyFactory.new.call(
          account: params[:account],
          factory_template: JSON.parse(Base64.decode64(factory)),
          request_body: request.body.read,
          authorization: request.headers["Authorization"]
        )
      end

    if response.success?
      render(json: JSON.parse(response.result), status: :created)
    else
      render(json: error_response(response), status: response.status)
    end
  end

  def info
    factory_resource = load_factory(kind: params[:kind], id: params[:id], account: params[:account])
    authorize(:execute, factory_resource)

    template = JSON.parse(Base64.decode64(factory_resource.secret.value))
    render(json: template['schema'])
  end

  private

  def error_response(response)
    rtn = {
      status: response.status,
      body: { errors: [] }
    }
    if response.message.is_a?(Array)
      rtn[:body][:errors] == response.message
    else
      rtn[:body][:errors] << {
        message: response.message
      }
    end
  end

  def load_factory(kind:, id:, account:)
    factory_resource = Resource["#{account}:variable:conjur/factories/#{kind}/#{id}"]
    if factory_resource.blank?
      return ::FailureResponse.new(
        "Policy Factory '#{kind}/#{id}' does not exist in account '#{account}'",
        status: :not_found
      )
    end

    if current_user.allowed_to?(:execute, factory_resource)
      if factory_resource.secret.present?
        ::SuccessResponse.new(factory_resource.secret.value)
      else
        ::FailureResponse.new(
          "Policy Factory '#{kind}/#{id}' in account '#{account}' has not been initialized",
          status: :bad_request
        )
      end
    else
      ::FailureResponse.new(
        "Role '#{current_user}' does not have access to Policy Factory '#{kind}/#{id}' does not exist in account '#{account}'",
        status: :forbidden
      )
    end
  end
end

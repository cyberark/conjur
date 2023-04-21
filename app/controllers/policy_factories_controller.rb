# frozen_string_literal: true

require './app/domain/responses'

class PolicyFactoriesController < RestController
  include AuthorizeResource

  before_action :current_user

  def create
    response = DB::Repository::PolicyFactoryRepository.new.find(
      role: current_user,
      **relevant_params(%i[account kind version id])
    ).bind do |factory|
      Factories::CreateFromPolicyFactory.new.call(
        account: params[:account],
        factory_template: factory,
        request_body: request.body.read,
        authorization: request.headers["Authorization"]
      )
    end

    render_response(response) do
      render(json: response.result)
    end
  end

  def show
    allowed_params = %i[account kind version id]
    response = DB::Repository::PolicyFactoryRepository.new.find(
      role: current_user,
      **relevant_params(allowed_params)
    )

    render_response(response) do
      render(json: response.result.schema)
    end
  end

  def index
    response = DB::Repository::PolicyFactoryRepository.new.find_all(
      role: current_user,
      account: params[:account]
    )
    render_response(response) do
      response_body = response.result.map do |factory|
        {
          name: factory.name,
          namespace: factory.classification,
          'full-name': "#{factory.classification}/#{factory.name}",
          'current-version': factory.version,
          description: factory.description || ''
        }
      end
      render(json: response_body)
    end
  end

  private

  def render_response(response, &block)
    if response.success?
      block.call
    else
      render(
        json: response.message.merge(
          code: HTTP::Response::Status::SYMBOL_CODES[response.status]
        ),
        status: response.status
      )
    end
  end

  def relevant_params(allowed_params)
    params.permit(*allowed_params).slice(*allowed_params).to_h.symbolize_keys
  end
end

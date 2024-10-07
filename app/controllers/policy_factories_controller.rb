# frozen_string_literal: true

require './app/domain/responses'

# This controller is responsible for managing Policy Factory templates
class PolicyFactoriesController < RestController
  include AuthorizeResource
  include PolicyFactory
  include RequestContext

  before_action :current_user

  def index
    response = DB::Repository::PolicyFactoryRepository.new.find_all(
      context: context,
      account: params[:account]
    )
    render_response(response) do
      presenter = Presenter::PolicyFactories::Index.new(factories: response.result)
      render(json: presenter.present)
    end
  end

  def show
    allowed_params = %i[account kind version id]
    response = DB::Repository::PolicyFactoryRepository.new.find(
      context: context,
      **relevant_params(allowed_params)
    )

    render_response(response) do
      presenter = Presenter::PolicyFactories::Show.new(factory: response.result)
      render(json: presenter.present)
    end
  end
end

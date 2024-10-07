# frozen_string_literal: true

require './app/domain/responses'

# This controller is responsible for managing resources created by
# Policy Factory templates
class PolicyFactoryResourcesController < RestController
  include AuthorizeResource
  include PolicyFactory
  include RequestContext

  before_action :current_user

  # Create a resource(s) from a factory
  def create
    available_params = relevant_params(%i[account kind version id])

    response = DB::Repository::PolicyFactoryRepository.new.find(
      context: context,
      kind: available_params[:kind],
      account: available_params[:account],
      id: available_params[:id],
      version: available_params[:version]
    ).bind do |factory|
      Factories::CreateFromPolicyFactory.new.call(
        account: available_params[:account],
        factory_template: factory,
        request_body: request.body.read,
        context: context,
        request_method: request.request_method
      )
    end
    render_response(response) do
      render(json: response.result, status: :created)
    end
  end
end

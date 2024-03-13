# frozen_string_literal: true

# Helper methods for Policy Factory related controllers
module PolicyFactory
  def relevant_params(allowed_params)
    params.permit(*allowed_params).slice(*allowed_params).to_h.symbolize_keys
  end

  def render_response(response, &block)
    if response.success?
      block.call
    else
      presenter = Presenter::PolicyFactories::Error.new(response: response)
      render(
        json: presenter.present,
        status: response.status
      )
    end
  end
end

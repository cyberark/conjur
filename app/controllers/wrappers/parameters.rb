# frozen_string_literal: true

class ParametersWithRise < ActionController::Parameters

  private

  def unpermitted_parameters!(params)
    unpermitted_keys = unpermitted_keys(params)
    return unless unpermitted_keys.any?

    raise ActionController::UnpermittedParameters, unpermitted_keys
  end
end

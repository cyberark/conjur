# frozen_string_literal: true

module SynchronizerYamls
  extend ActiveSupport::Concern
  def input_post_yaml(json_body)
    {
      "synchronizer_identifier" => json_body
    }
  end
end

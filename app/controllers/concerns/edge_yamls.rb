module EdgeYamls
  extend ActiveSupport::Concern
  def input_post_yaml(json_body)
    {
      "edge_identifier" => json_body
    }
  end
end

# @api private
module Conjur::QueryString
  protected

  def options_querystring options
    if options.empty?
      ""
    else
      "?#{options.to_query}"
    end
  end
end

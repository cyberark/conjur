module Authenticates
  extend ActiveSupport::Concern
  
  def authentication
    @authentication ||= Authentication.new
  end
end

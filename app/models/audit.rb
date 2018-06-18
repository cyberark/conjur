module Audit
  class << self
    def logger
      @logger ||= Rails.logger
    end

    attr_writer :logger
  end
end

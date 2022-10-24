# frozen_string_literal: true

class TestExtensionA
  def initialize(logger:)
    @logger = logger
  end

  def on_callback(**_kwarg); end
end

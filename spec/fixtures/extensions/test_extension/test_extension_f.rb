# frozen_string_literal: true

class TestExtensionF
  def on_callback
    raise 'failure in the extension'
  end
end

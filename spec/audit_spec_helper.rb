# frozen_string_literal: true

def expect_audit(message:, result:, operation:)
  expect(log_output.string).to include("result=\"#{result}\"")
  expect(log_output.string).to include("operation=\"#{operation}\"")
  expect(log_output.string).to include(message)
end

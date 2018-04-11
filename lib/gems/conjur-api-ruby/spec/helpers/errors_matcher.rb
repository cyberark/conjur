require 'rspec/expectations'

RSpec::Matchers.define :raise_one_of do |*exn_classes|
  supports_block_expectations

  match do |block|
    expect(&block).to raise_error do |error|
      @actual_error = error
      expect(exn_classes).to include error.class
    end
  end

  failure_message do
    "expected #{expected_error}#{given_error}"
  end

  define_method :expected_error do
    "one of " + exn_classes.join(', ')
  end

  def given_error
    return " but nothing was raised" unless @actual_error
    backtrace = format_backtrace(@actual_error.backtrace)
    [
      ", got #{@actual_error.inspect} with backtrace:",
      *backtrace
    ].join("\n  # ")
  end

  def format_backtrace backtrace
    formatter = RSpec::Matchers.configuration.backtrace_formatter
    formatter.format_backtrace(backtrace)
  end
end

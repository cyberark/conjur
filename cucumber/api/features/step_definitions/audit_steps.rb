# frozen_string_literal: true

require_relative '../support/logs_helpers'

Given(/^I save my place in the audit log file for remote$/) do
  save_num_log_lines unless Utils.local_conjur_server
end

Then(/^there is an audit record matching:$/) do |given|
  if Utils.local_conjur_server
    expect(audit_messages).to include(matching(audit_template(given)))
  else
    expect(num_matches_since_savepoint(normalized_to_log(given))).to be >= 1
  end
end

module CucumberAuditHelper
  def audit_messages
    Test::AuditSink.messages.map(&method(:normalized_message))
  end

  def last_message
    normalized_message Test::AuditSink.messages.last
  end

  def audit_template template
    normalized_message(template).map(&method(:matcher))
  end
  
  private

  # I suppose it's acceptable to :reek:UtilityFunction
  # for this test-related method
  def normalized_message(message)
    raise ArgumentError, "no audit message received" unless message
    *fields, tail = message
      .gsub(/\s+/m, ' ')
      .gsub(/\] \[/, '][')
      .split(' ', 7)
    *sdata, msg = tail.split(/(?<=\])/).map(&:strip)
    sdata, msg = msg.split ' ', 2 if sdata.empty?
    [*fields, sdata_split(sdata), msg]
  end
  
  def sdata_split sdata
    Array(sdata).map! { |element| element[/\[(.*)\]/, 1].split(' ') }
  end

  def matcher val
    case val
    when '*' then be
    when Array then match_array val.map(&method(:match_array))
    else match val
    end
  end

  def normalized_to_log(message)
    message
      .gsub(/\*/, '.*')
      .gsub(/^\s+/, '\s?')
      .gsub(/\n/, '')
      .gsub(/\[/, '\[')
      .gsub(/\]/, '\]')
  end
end

Before { Test::AuditSink.messages.clear }

World CucumberAuditHelper

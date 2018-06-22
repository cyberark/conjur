Then(/^there is an audit record matching:$/) do |given|
  if Utils.local_conjur_server
    expect(audit_messages).to include(matching(audit_template(given)))
  else
    puts "Note: audit tests currently rely on in-process server, skipping"
  end
end

module CucumberAuditHelper
  def audit_messages
    Test::AuditSink.messages.map(&method(:normalize_message))
  end

  def last_message
    normalize_message Test::AuditSink.messages.last
  end

  def audit_template template
    normalize_message(template).map(&method(:matcher))
  end
  
  private

  # I suppose it's acceptable to :reek:UtilityFunction
  # for this test-related method
  def normalize_message message
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
end

Before { Test::AuditSink.messages.clear }

World CucumberAuditHelper

require 'logger/formatter/rfc5424_formatter'

describe Logger::Formatter::RFC5424Formatter do
  it "can be given facility by object attribute" do
    msg = double "message", facility: 40
    expect(formatter.call(3, Time.now, nil, msg)).to start_with '<43>'
  end

  subject(:formatter) { described_class }
end

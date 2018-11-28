# frozen_string_literal: true

require 'logger/formatter/rfc5424_formatter'

describe Logger::Formatter::RFC5424Formatter do
  it "can be given facility by object attribute" do
    msg = double "message", facility: 40
    expect(formatter.call(3, Time.now, nil, msg)).to start_with '<43>'
  end

  describe "with structured data" do
    describe "escapes" do
      it "quote" do
        params = { quote: '"' }
        formatted = described_class::Format.sd_parameters params
        expect(formatted).to eq ["quote=\"\\\"\""]
      end

      it "backslash" do
        params = { backslash: '\\' }
        formatted = described_class::Format.sd_parameters params
        expect(formatted).to eq ["backslash=\"\\\\\""]
      end

      it "bracket" do
        params = { bracket: ']' }
        formatted = described_class::Format.sd_parameters params
        expect(formatted).to eq ["bracket=\"\\]\""]
      end
    end
  end

  subject(:formatter) { described_class }
end

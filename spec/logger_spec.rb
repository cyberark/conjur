# frozen_string_literal: true

require 'logger/formatter/rfc5424_formatter'

describe Logger::Formatter::RFC5424Formatter do
  describe "with no set request_id" do 
    it "writes the expected log line" do
      # Notes:
      #   The "\\d+" represents a process id that changes each run.
      #   "#{time_str}" avoids time of day / time zone issues.
      expect(
        formatter.call("_", known_time, progname, my_event)
      ).to match(
        Regexp.new(
          "<43>1 #{time_str} - conjur \\d+ my_message_id " \
          '\\[1 key1="11"\\]\\[8 key2="22"\\] my sample message'
        )
      )
    end

    describe "with structured data" do
      describe "escapes" do
        it "quote" do
          params = { quote: '"' }
          formatted = described_class::Format.sd_parameters(params)
          expect(formatted).to eq(["quote=\"\\\"\""])
        end

        it "backslash" do
          params = { backslash: '\\' }
          formatted = described_class::Format.sd_parameters(params)
          expect(formatted).to eq(["backslash=\"\\\\\""])
        end

        it "bracket" do
          params = { bracket: ']' }
          formatted = described_class::Format.sd_parameters(params)
          expect(formatted).to eq(["bracket=\"\\]\""])
        end
      end
    end
  end

  describe "with set request_id" do
    let(:request_id){ 'ConjurTest' }

    # Reset the thread's `request_id`
    after(:each) do
      Thread.current[:request_id] = nil
    end

    it "writes the expected log line" do
      # Ensure that if a Thread's request_id is set, 
      # then it appears in the audit record.
      Thread.current[:request_id] = request_id

      # Notes:
      #   "#{time_str}" avoids time of day / time zone issues.
      expect(
        formatter.call("_", known_time, progname, my_event)
      ).to match(
        Regexp.new(
          "<43>1 #{time_str} - conjur #{request_id} my_message_id " \
          '\\[1 key1="11"\\]\\[8 key2="22"\\] my sample message'
        )
      )
    end
  end

  subject(:formatter) { described_class }

  let(:my_event) do
    msg = double(
      "message",
      facility: 40,
      message: message,
      message_id: "my_message_id",
      progname: progname,
      severity: 3,
      structured_data: {
        1 => { key1: 11 },
        8 => { key2: 22 }
      },
      to_s: message
    )
  end

  let(:message) { "my sample message" }
  let(:progname) { "conjur" }

  # Time.parse('2020-06-22').utc.iso8601(3) => "2020-06-22T04:00:00.000Z"
  let(:known_time) { Time.parse('2020-06-22') }
  let(:time_str) { known_time.utc.iso8601(3) }
end

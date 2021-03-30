# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Util::TrackableLogMessageClass') do
  let(:log_code) { "ABC123" }
  let(:log_message) { "An error occured" }

  let(:trackable_log_message) { "#{log_code} #{log_message}" }

  subject(:trackable_log_class) do
    Util::TrackableLogMessageClass.new(
      msg: log_message,
      code: log_code
    )
  end

  it 'has the expected messaged error' do
    expect(trackable_log_class.new.to_s).to eq(trackable_log_message)
  end
end

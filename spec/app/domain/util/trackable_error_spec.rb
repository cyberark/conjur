# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Util::TrackableErrorClass') do
  context 'object' do
    let(:error_code) { "ABC123" }
    let(:error_message) { "An error occured" }

    let(:trackable_error_message) { "#{error_code} #{error_message}" }

    subject(:trackable_error_class) do
      Util::TrackableErrorClass.new(
        msg: error_message,
        code: error_code
      )
    end

    it 'has the expected messaged error' do
      expect { raise trackable_error_class }.to raise_error(trackable_error_message)
    end
  end
end

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

require 'util/error_code'

describe Error::ConjurCode do
  let(:error_code_valid) do
    Error::ConjurCode.new('./spec/app/domain/util/errors/valid')
  end
  let(:error_code_invalid) { Error::ConjurCode.new('invalid_file_path') }
  let(:error_code_empty) do
    Error::ConjurCode.new('./spec/app/domain/util/errors/empty')
  end
  
  it 'raises error when file path is invalid' do
    expect { error_code_invalid }.to raise_error(RuntimeError)
  end

  it 'outputs the next available error code' do 
    expect do
      error_code_valid.print_next_available
    end.to output(
      "The next available error number is 5 ( CONJ00005E )\n"
    ).to_stdout
  end

  it 'outputs that the file lacks error codes' do 
    expect do
      error_code_empty.print_next_available
    end.to output(
      "The path doesn't contain any files with Conjur error codes\n"
    ).to_stderr
  end
end

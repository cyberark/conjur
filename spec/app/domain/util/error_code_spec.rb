# frozen_string_literal: true

require 'spec_helper'

require 'util/error_code'

describe Error::ConjurCode do
  subject do
    Error::ConjurCode.new(
      path,
      logger: logger_double,
      output: output_double
    )
  end

  let(:path) { './spec/app/domain/util/errors/valid' }

  let(:logger_double) { Logger.new(log_output) }
  let(:log_output) { StringIO.new }

  let(:output_double) { StringIO.new }

  it 'returns the error code' do
    expect(subject.print_next_available).to eq(5)
  end

  it 'outputs the next available error code' do
    subject.print_next_available

    expect(output_double.string).to include(
      "The next available error number is 5 ( CONJ00005 )\n"
    )
  end

  context 'when the file path is invalid' do
    let(:path) { 'invalid_file_path' }

    it 'returns nil' do
      expect(subject.print_next_available).to be_nil
    end

    it 'logs an error' do
      subject
      expect(log_output.string).to include(
        "The following path was not found: invalid_file_path"
      )
    end
  end

  context 'when the file lacks error codes' do
    let(:path) { './spec/app/domain/util/errors/empty' }

    it 'returns nil' do
      expect(subject.print_next_available).to be_nil
    end

    it 'outputs that the file lacks error codes' do
      subject.print_next_available
      expect(log_output.string).to include(
        "The path doesn't contain any files with Conjur error codes\n"
      )
    end
  end
end

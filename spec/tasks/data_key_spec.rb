# frozen_string_literal: true

require 'spec_helper'

Rails.application.load_tasks

BASE64_REGEX = %r(^[-A-Za-z0-9+/]*={0,3}$).freeze

describe 'data-key.rake' do
  subject { Rake::Task['data-key:generate'] }

  let(:stdout_double) { StringIO.new }

  before do
    $stdout = stdout_double
  end

  after do
    $stdout = STDOUT

    # Allow the task to run again for subsequent tests
    subject.reenable
  end

  it 'prints a base64-encoded random key' do
    # Run the task
    subject.invoke

    # Verify the output is base64-encoded
    expect(stdout_double.string).to match(BASE64_REGEX)
  end
end

require 'spec_helper'


RSpec.describe 'Redis' do
  it 'sets and gets a key' do
    Rails.cache.write('test_key', 'test_value1', raw: true)

    # Retrieve the value from the cache
    value = Rails.cache.read('test_key', raw: true)
    puts value
    # Expect the value to be what we set
    expect(value).to eq('test_value1')
  end
end
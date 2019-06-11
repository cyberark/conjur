require 'spec_helper'

# Create a sample class to wrap
#
class Count
  def initialize
    @count = 0
  end

  def call
    @count += 1
  end
end

# A double to control time
#
class TimeDouble
  attr_accessor :now
end

RSpec.describe 'Util::RateLimitedCache' do

  context "Multiple calls within the rate limit interval" do

    subject(:cached_count) do
      Util::RateLimitedCache.new(
        Count.new,
        refreshes_per_interval: 3, 
        rate_limit_interval: 3600,
        logger: Rails.logger
      )
    end

    it "should work the same as what it's wrapping" do
      expect(cached_count.call).to eq(1)
    end

    it "should return cached values" do
      cached_count.call
      expect(cached_count.call).to eq(1)
    end

    it "should recalculate upon request" do
      cached_count.call
      expect(cached_count.call(refresh: true)).to eq(2)
    end

    it "should only recalculate the rate-limited number of times" do
      cached_count.call # call 1
      expect(cached_count.call(refresh: true)).to eq(2) # call 2
      expect(cached_count.call(refresh: true)).to eq(3) # call 3
      expect(cached_count.call(refresh: true)).to eq(3) # passed limit - don't refresh
    end

  end

  #TODO another example with differet params, to test
  #     that keys are cached independently

  context "Multiple calls across rate limit intervals" do

    def new_cached_count(time)
      Util::RateLimitedCache.new(
        Count.new,
        refreshes_per_interval: 3, 
        rate_limit_interval: 10,
        time: time,
        logger: Rails.logger
      )
    end

    it "should allow refreshing again when we enter a new rate interval" do
      time = TimeDouble.new
      cached_count = new_cached_count(time)

      time.now = 0
      expect(cached_count.call).to eq(1)
      expect(cached_count.call(refresh: true)).to eq(2)
      expect(cached_count.call(refresh: true)).to eq(3)
      expect(cached_count.call(refresh: true)).to eq(3) # passed limit - no refresh
      time.now = 9
      expect(cached_count.call(refresh: true)).to eq(3) # still 1st interval - no refresh
      time.now = 10
      expect(cached_count.call(refresh: true)).to eq(4) # new interval - refresh again
    end
  end
end

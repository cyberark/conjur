require 'spec_helper'

@@is_threads_blocked = false
@@is_threads_failed = false
TARGET_EXCEPTION = "dummy exception"

class ConcurrencyCount

  def initialize
    @count = 0
  end

  def call(**args)
    @count += 1
    # Simulate thread failure
    raise TARGET_EXCEPTION if @@is_threads_failed
    # Simulate threads work
    while @@is_threads_blocked
    end
    @count
  end
end

RSpec.describe 'Util::ConcurrencyLimitedCache' do
  before (:each) do
    @@is_threads_blocked = false
    @@is_threads_failed = false
    @currentConcurrencyCount = ConcurrencyCount.new
  end

  context "Multiple calls within concurrency limit" do

    subject(:cached_count_unlimit) do
      Util::ConcurrencyLimitedCache.new(
          @currentConcurrencyCount,
          max_concurrent_requests: 100,
          logger: Rails.logger
      )
    end

    it "it should work the same as what it's wrapping" do
      @@is_threads_failed = false
      expect(cached_count_unlimit.call).to eq(1)

      @@is_threads_failed = true
      expect{ cached_count_unlimit.call }.to raise_error(TARGET_EXCEPTION)
    end

    it "it should return cached values" do
      cached_count_unlimit.call(key: "key1")
      cached_count_unlimit.call(key: "key2")
      cached_count_unlimit.call(key: "key3")
      cached_count_unlimit.call(key: "key4")
      expect(cached_count_unlimit.call).to eq(5)
    end

    it "it should work the same as what it's wrapping in concurrency" do
      # Simulate concurrency work
      queue = (1..10).inject(Queue.new, :push)
      all_threads = Array.new(10) do
        Thread.new do
          until queue.empty? do
            queue.shift
            cached_count_unlimit.call
          end
        end
      end

      # Wait for threads to be stuck on target call
      all_threads.each(&:join)

      # The above threads died before updating the cache value
      expect(cached_count_unlimit.call).to eq(11)
    end

  end

  context "Multiple calls across concurrency limit" do

    subject(:cached_count) do
      Util::ConcurrencyLimitedCache.new(
          @currentConcurrencyCount,
          max_concurrent_requests: 4,
          logger: Rails.logger
      )
    end

    it "should throw error when we reached concurrency limit and cache uninitialized" do
      # Simulate concurrency work
      queue = (1..4).inject(Queue.new, :push)
      @@is_threads_blocked = true
      all_threads = Array.new(4) do
        Thread.new do
          until queue.empty? do
            queue.shift
            cached_count.call
          end
        end
      end

      # Wait for threads to be stuck on target call
      sleep(2.second)
      all_threads.each(&:kill)

      expect{ cached_count.call }.to raise_error(Errors::Util::ConcurrencyLimitReachedBeforeCacheInitialization)
    end

    it "should return the cache value when we reached concurrency limit" do
      # Initialize cache
      @@is_threads_blocked = false

      expect(cached_count.call).to eq(1)

      # Simulate concurrency work
      queue = (1..4).inject(Queue.new, :push)
      @@is_threads_blocked = true
      all_threads = Array.new(4) do
        Thread.new do
          until queue.empty? do
            queue.shift
            cached_count.call
          end
        end
      end

      # Wait for threads to be stuck on target call
      sleep(2.second)
      all_threads.each(&:kill)

      # The above threads died before updating the cache value
      expect(cached_count.call).to eq(1)
    end

  end
end
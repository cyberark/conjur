require 'spec_helper'

TARGET_EXCEPTION = "dummy exception"

class ConcurrencyCount

  attr_accessor :threads_blocked, :threads_failed

  def initialize(threads_blocked, threads_failed)
    @thread_blocked = threads_blocked
    @threads_failed = threads_failed
    @count = 0
  end

  def call(**_args)
    @count += 1
    # Simulate thread failure
    raise TARGET_EXCEPTION if @threads_failed

    # Simulate threads work
    while @threads_blocked
    end
    @count
  end
end

RSpec.describe('Util::ConcurrencyLimitedCache') do
  let(:threads_blocked) { false }
  let(:threads_failed) { false }
  let(:current_concurrency_count) do
    ConcurrencyCount.new(
      threads_blocked,
      threads_failed
    )
  end

  context "Multiple calls within concurrency limit" do
    subject(:cached_count_unlimited) do
      Util::ConcurrencyLimitedCache.new(
        current_concurrency_count,
        max_concurrent_requests: 100,
        logger: Rails.logger
      )
    end

    it "should work the same as what it's wrapping" do
      current_concurrency_count.threads_failed = false
      expect(cached_count_unlimited.call).to eq(1)

      current_concurrency_count.threads_failed = true
      expect { cached_count_unlimited.call }.to raise_error(TARGET_EXCEPTION)
    end

    it "should return cached values" do
      cached_count_unlimited.call(key: "key1")
      cached_count_unlimited.call(key: "key2")
      cached_count_unlimited.call(key: "key3")
      cached_count_unlimited.call(key: "key4")
      expect(cached_count_unlimited.call).to eq(5)
    end

    it "should work the same as what it's wrapping in concurrency" do
      # Simulate concurrency work
      queue = (1..10).inject(Queue.new, :push)
      all_threads = Array.new(10) do
        Thread.new do
          until queue.empty?
            queue.shift
            cached_count_unlimited.call
          end
        end
      end

      # Wait for threads to be stuck on target call
      all_threads.each(&:join)

      # The above threads died before updating the cache value
      expect(cached_count_unlimited.call).to eq(11)
    end
  end

  context "Multiple calls across concurrency limit" do
    subject(:cached_count) do
      Util::ConcurrencyLimitedCache.new(
        current_concurrency_count,
        max_concurrent_requests: 4,
        logger: Rails.logger
      )
    end

    it "should throw error when we reached concurrency limit and cache uninitialized" do
      # Simulate concurrency work
      queue = (1..4).inject(Queue.new, :push)
      current_concurrency_count.threads_blocked = true
      all_threads = Array.new(4) do
        Thread.new do
          until queue.empty?
            queue.shift
            cached_count.call
          end
        end
      end

      # Wait for threads to be stuck on target call
      sleep(2.second)
      all_threads.each(&:kill)

      expect { cached_count.call }.to raise_error(Errors::Util::ConcurrencyLimitReachedBeforeCacheInitialization)
    end

    it "should return the cache value when we reached concurrency limit" do
      # Initialize cache
      current_concurrency_count.threads_blocked = false

      expect(cached_count.call).to eq(1)

      # Simulate concurrency work
      queue = (1..4).inject(Queue.new, :push)
      current_concurrency_count.threads_blocked = true
      all_threads = Array.new(4) do
        Thread.new do
          until queue.empty?
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

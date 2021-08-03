module Util

  class ConcurrencyLimitedCache

    # NOTE: "callable" is anything with a "call" method
    def initialize(
      callable,
      max_concurrent_requests:,
      logger:
    )
      @target = callable
      @cache = {}
      @semaphore = Mutex.new
      @concurrency_mutex = Mutex.new
      @max_concurrent_requests = max_concurrent_requests
      @concurrent_requests = 0
      @logger = logger
    end

    # This  method is passed exactly the same named arguments you'd pass to the
    # callable object, but you can optionally include the `refresh: true` to
    # force recalculation.
    def call(**args)
      cache_key = cached_key(args)
      @concurrency_mutex.synchronize do
        if @concurrent_requests >= @max_concurrent_requests
          @logger.debug(
            LogMessages::Util::ConcurrencyLimitedCacheReached.new(@max_concurrent_requests)
          )
          raise Errors::Util::ConcurrencyLimitReachedBeforeCacheInitialization unless @cache.key?(cache_key)

          return @cache[cache_key]
        end

        @concurrent_requests += 1
        @logger.debug(
          LogMessages::Util::ConcurrencyLimitedCacheConcurrentRequestsUpdated.new(
            @concurrent_requests
          )
        )
      end

      @semaphore.synchronize do
        recalculate(args)
        @cache[cache_key]
      end
    end

    private

    def recalculate(args)
      cache_key = cached_key(args)
      @cache[cache_key] = @target.call(**args)
      @logger.debug(LogMessages::Util::ConcurrencyLimitedCacheUpdated.new)
      decrease_concurrent_requests
    rescue => e
      decrease_concurrent_requests
      raise e
    end

    def decrease_concurrent_requests
      unless @concurrent_requests.zero?
        @concurrent_requests -= 1
        @logger.debug(
          LogMessages::Util::ConcurrencyLimitedCacheConcurrentRequestsUpdated.new(
            @concurrent_requests
          )
        )
      end
    end

    def cached_key(args)
      if args.has_key?(:cache_key)
        cache_key = args.fetch(:cache_key)
        return cache_key
      end
      args
    end
  end
end

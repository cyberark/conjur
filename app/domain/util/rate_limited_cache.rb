module Util

  # This can wrap any "callable" object (anything with a `call` method)
  # to add caching with optional force refreshing, where the refreshing
  # is itself subject to rate limiting.
  #
  # That is:
  #
  # 1. By default cached values are always returned when available
  # 2. You can force the cached value to be refreshed/recalculated by adding 
  #    a `refresh: true` to the named arguments.
  # 3. However, your refreshes are rate-limited.  If you exceed the limit,
  #    refresh requests will be ignored until enough time passes.
  #
  # The `RateLimitedCache` instance is passed exactly the same named arguments
  # you'd pass to the callable object, but you can optionally include the
  # `refresh: true` to force recalculation.
  #
  class RateLimitedCache

    # NOTE: "callable" is anything with a "call" method
    def initialize(
      callable,
      refreshes_per_interval:,
      rate_limit_interval:,    # in seconds
      logger:, time: Time
    )
      @target = callable
      @refreshes_per_interval = refreshes_per_interval
      @rate_limit_interval = rate_limit_interval
      @time = time
      @cache = {}
      @refresh_history = Hash.new([]) # default history is an empty list
      @semaphore = Mutex.new
      @logger = logger
    end

    # This  method is passed exactly the same named arguments you'd pass to the
    # callable object, but you can optionally include the `refresh: true` to
    # force recalculation.
    def call(**args)
      refresh_requested = args[:refresh]
      args.delete(:refresh)

      @semaphore.synchronize do
        cache_key = cached_key(args)
        first_calculation = !@cache.key?(cache_key)
        recalculate(args, cache_key) if refresh_requested || first_calculation

        @cache[cache_key]
      end
    end

    private

    def recalculate(args, cache_key)
      if too_many_requests?(cache_key)
        @logger.debug(
          LogMessages::Util::RateLimitedCacheLimitReached.new(
            @refreshes_per_interval,
            @rate_limit_interval
          )
        )
        return
      end
      @cache[cache_key] = @target.call(**args)
      @logger.debug(LogMessages::Util::RateLimitedCacheUpdated.new)
      @refresh_history[cache_key].push(@time.now)
    end

    def cached_key(args)
      if args.has_key?(:cache_key)
        cache_key = args.fetch(:cache_key)
        args.delete(:cache_key)
        return cache_key
      end
      args
    end

    def too_many_requests?(args)
      @logger.debug("tamir @refresh_history before prune")
      @logger.debug(@refresh_history.to_s)
      prune_old_requests(args)
      @logger.debug("tamir @refresh_history after prune")
      @logger.debug(@refresh_history.to_s)
      @refresh_history[args].size >= @refreshes_per_interval
    end

    def prune_old_requests(args)
      @refresh_history[args] = @refresh_history[args].drop_while do |timestamp|
        @time.now - timestamp >= @rate_limit_interval
      end
    end
  end
end

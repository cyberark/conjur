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
      time: Time,
      logger:
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
        first_calculation = !@cache.key?(args)
        recalculate(args) if refresh_requested || first_calculation

        @cache[args]
      end
    end

    private

    def recalculate(args)
      if too_many_requests?(args)
        @logger.debug(
          LogMessages::Util::RateLimitedCacheLimitReached.new(
            @refreshes_per_interval,
            @rate_limit_interval
          )
        )
        return
      end
      @cache[args] = @target.call(**args)
      @logger.debug(LogMessages::Util::RateLimitedCacheUpdated.new)
      @refresh_history[args].push(@time.now)
    end

    def too_many_requests?(args)
      prune_old_requests(args)
      @refresh_history[args].size >= @refreshes_per_interval
    end

    def prune_old_requests(args)
      @refresh_history[args] = @refresh_history[args].drop_while do |timestamp|
        @time.now - timestamp >= @rate_limit_interval
      end
    end
  end
end

module Conjur
  # A cache which performs no caching.
  class BaseCache
    def fetch_attributes cache_key, &block
      yield
    end
  end

  class << self
    @@cache = BaseCache.new

    # Sets the global cache. It should implement +fetch_:method+ methods.
    # The easy way to accomplish this is to extend BaseCache.
    def cache= cache
      @@cache = cache
    end

    # Gets the global cache.
    def cache; @@cache; end

    # Builds a cache key from a +username+, +url+ and optional +path+.
    def cache_key username, url, path = nil
      [ username, [ url, path ].compact.join ].join(".")
    end
  end
end

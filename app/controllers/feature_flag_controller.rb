
class FeatureFlagController < RestController

  def feature_flag
    filtered_features = ""
    # Controllers are created per request, so we must use a class variable to cache the result
    # of the app config call.  We use a mutex to ensure that only one thread is updating the cache
    Mutex.new.synchronize do
      @@result_cache ||= Util::TimeExpiredCache.new(60) {Aws::AppConfigDataClient.new.get_latest_configuration}
      filtered_features = @@result_cache.result
    end
    render(json: filtered_features)
  end

  def purge_result
    Mutex.new.synchronize do
      @@result_cache = nil
    end
  end
end
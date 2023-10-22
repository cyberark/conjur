#$redis = Redis.new(url: "rediss://master.ofira-redis1.ejau9l.use2.cache.amazonaws.com:6582/")

#$redis = Redis.new(host: "127.0.0.1", port: 6379, db: 0)
$redis = Redis.new(url: ENV['REDIS_URL'])
#$redis = Redis.new(url: "rediss://clustercfg.ofira-bench-poc.68b8fl.use1.cache.amazonaws.com:6379/")
#$redis = Redis.new(url: "rediss://clustercfg.ofira-redis3.ejau9l.use2.cache.amazonaws.com:6379/")

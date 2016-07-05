Before do
  timestamp = Time.now.utc.strftime('%Y-%m-%dT%H%M%S.%LZ')
  @namespace = [ 'cucumber', timestamp, 4.times.map{rand(255).to_s(16)}.join ].join('/')
end
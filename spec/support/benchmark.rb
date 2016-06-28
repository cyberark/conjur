require 'benchmark'
require 'parallel'
require 'csv'

RSpec::Matchers.define :handle do |rps|
  chain :requests_per_second do; end
  
  def title
    @title ||= begin
      metadata = RSpec.current_example.example_group.metadata
      metadata.extend RSpec::Core::Metadata::GroupMetadataHash
      metadata.full_description
    end
  end
  
  def record_result
    values = (CSV.read "performance.csv", headers: true rescue CSV::Table.new([]))
    values[0] ||= []
    values[0][title] = @result
    File.write "performance.csv", values.to_s
  end
  
  match do |block|
    begin
      # try to disconnect before forking
      Sequel::Model.db.disconnect
    rescue
    end

    @count = 0
    @elapsed  = 0
    
    pcount = Parallel.processor_count
    chunk = 16
    @elapsed = Benchmark.realtime do
      Parallel.each(1..pcount) { chunk.times &block }
    end
    @count = pcount * chunk
    @result = @count / @elapsed
    
    record_result
    @result >= rps
  end
    
  failure_message_for_should do
    "expected to handle more than %.02f requests per second (%.02f handled)" % [rps, @result]
  end
  
  failure_message_for_should_not do
    "expected to handle less than %.02f requests per second (%.02f handled)" % [rps, @result]
  end
end

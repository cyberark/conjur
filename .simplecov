require 'socket'

SimpleCov.start('rails') do
  command_name "SimpleCov #{rand(1000000)}"
  coverage_dir File.join(ENV['REPORT_ROOT'] || __dir__, 'coverage')
  merge_timeout 7200 # Set largest gap between resultsets of 30 minutes
  # any custom configs like groups and filters can be here at a central place
  enable_coverage :branch
  primary_coverage :branch
end

# Generate coverage report on exit, this is not going to interfere with the socket server approach and is meant for a
# different use case. This will generate the report when the process exits and there is no need to keep process running
# to keep the pod alive until the report can be gathered by the CI.
SimpleCov.at_exit do
  puts "Formatting SimpleCov coverage report"
  SimpleCov.result.format!
  if ENV['SIMPLECOV_SLEEP']
    puts "Coverage Report Generated, sleeping forever"
    sleep
  end
end

# We open a UNIX socket server to listen for requests to generate the report. The coverage data is gathered from the
# service process and integration tests are executed in a separate process. This allows us to generate the report
# after the integration tests are executed in a synchronous way. This will prevent from attempt go gather the report
# before it is fully generated since the socket communication will block the request until the report is generated.
# The socket server will listen for a request to generate the report and will return a message when the report is
# generated. Intentionally this will support only a single request to generate the report, subsequent requests should
# be treated as an error.
server = UNIXServer.new("/tmp/simplecov.sock")

Thread.new do
  session = server.accept
  request = session.gets

  if request&.strip == "generate_report"
    SimpleCov.result.format!
    session.puts "Report generated"
  else
    session.puts "Unknown command"
  end
  session.close
end

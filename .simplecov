SimpleCov.start('rails') do
  command_name "SimpleCov #{rand(1000000)}"
  coverage_dir File.join(ENV['REPORT_ROOT'] || __dir__, 'coverage')
  merge_timeout 7200 # Set largest gap between resultsets of 30 minutes
  # any custom configs like groups and filters can be here at a central place
  enable_coverage :branch
  primary_coverage :branch
  print_error_status=false
end

SimpleCov.at_exit do
  sleep 300 # Temp Fix to Resolve Cucumber Test that Fails - Feature: Retrieving an API key with conjurctl
  puts "Formatting SimpleCov coverage report"
  SimpleCov.result.format!
  if ENV['SIMPLECOV_SLEEP']
    puts "Coverage Report Generated, sleeping forever"
    sleep
  end
end

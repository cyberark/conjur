require 'simplecov'

SimpleCov.start('rails') do
  #puts ">>>After start pid: #{fork_pid}"
  command_name "SimpleCov #{rand(1000000)}"
  coverage_dir File.join(ENV['REPORT_ROOT'] || __dir__, 'coverage')
  merge_timeout 7200 # Set largest gap between resultsets of 30 minutes
  # any custom configs like groups and filters can be here at a central place
  enable_coverage :branch
  primary_coverage :branch
  print_error_status = false
end

SimpleCov.at_exit do
  original_stdout = $stdout
  original_stderr = $stderr
  $stdout.reopen("/dev/null","w")
  $stderr.reopen("/dev/null","w")
  SimpleCov.result.format! 
  $stdout = original_stdout
  $stderr = original_stderr
end
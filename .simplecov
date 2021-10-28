require 'simplecov'

SimpleCov.enable_for_subprocesses true
SimpleCov.at_fork do
  SimpleCov.start('rails') do
    command_name "SimpleCov #{rand(1000000)}"
    coverage_dir File.join(ENV['REPORT_ROOT'] || __dir__, 'coverage')
    merge_timeout 7200 # Set largest gap between resultsets of 30 minutes
    # any custom configs like groups and filters can be here at a central place
    enable_coverage :branch
    primary_coverage :branch
    print_error_status = false
  end
end

SimpleCov.at_exit do
  # Redirecting stdout and stderr due to issue with simplecov output being read by conjurctl_steps.rb
  # test /"^the API Key is correct$"/ - and causing test to fail.  This prevents output from simplecov from displaying on stdout 
  # and impacting test results or code coverage metrics.  Additionally, this is simpler approach vs forking processes
  original_stdout = $stdout
  $stdout.reopen("/dev/null","w")
  SimpleCov.result.format! 
  $stdout = original_stdout
end
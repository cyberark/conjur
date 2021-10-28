require 'simplecov'

#SimpleCov.command_name "SimpleCov #{rand(1000000)}"
#SimpleCov.coverage_dir File.join(ENV['REPORT_ROOT'] || __dir__, 'coverage')
#SimpleCov.merge_timeout 7200 
# Set largest gap between resultsets of 30 minutes
# any custom configs like groups and filters can be here at a central place

# SimpleCov.enable_for_subprocesses true
# SimpleCov.at_fork do |pid|
fork do
  SimpleCov.command_name "SimpleCov #{rand(1000000)}"
  SimpleCov.coverage_dir File.join(ENV['REPORT_ROOT'] || __dir__, 'coverage')
  SimpleCov.merge_timeout 7200 # Set largest gap between resultsets of 30 minutes
  # any custom configs like groups and filters can be here at a central place
  SimpleCov.enable_coverage :branch
  SimpleCov.primary_coverage :branch
  SimpleCov.print_error_status=true
  SimpleCov.start('rails')
end

# SimpleCov.enable_for_subprocesses true
# SimpleCov.at_fork do |pid|
#   # This needs a unique name so it won't be ovewritten
#   #SimpleCov.command_name "#{SimpleCov.command_name} (subprocess: #{pid})"
#   SimpleCov.start('rails') do
#     command_name "SimpleCov #{rand(1000000)}"
#     coverage_dir File.join(ENV['REPORT_ROOT'] || __dir__, 'coverage')
#     merge_timeout 7200 # Set largest gap between resultsets of 30 minutes
#     # any custom configs like groups and filters can be here at a central place
#     enable_coverage :branch
#     primary_coverage :branch
#     print_error_status=true
#   end
# end

pid = Process.pid
SimpleCov.at_exit do
  if Process.pid == pid
    SimpleCov.result.format! 
  end

    ## Was seeing issue where this was writing to stdout and causing tests to fail
    ## Now identifying parent process id and on running when child tests are completed
    ## https://blog.yossarian.net/2018/04/01/Code-coverage-with-Simplecov-across-multiple-processes
    #SimpleCov.result.format! #  -- causing issue with output on stdout    
  if ENV['SIMPLECOV_SLEEP']
    puts "Coverage Report Generated, sleeping forever"
    sleep
  end
end
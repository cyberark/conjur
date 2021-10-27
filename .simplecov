pid = Process.pid
SimpleCov.at_exit do
  SimpleCov.result.format! if Process.pid == pid
  ## Was seeing issue where this was writing to stdout and causing tests to fail
  ## Now identifying parent process id and on running when child tests are completed
  ## https://blog.yossarian.net/2018/04/01/Code-coverage-with-Simplecov-across-multiple-processes
  #SimpleCov.result.format! #  -- causing issue with output on stdout
  if ENV['SIMPLECOV_SLEEP']
    puts "Coverage Report Generated, sleeping forever"
    sleep
  end
end


fork do
  SimpleCov.start('rails') do
    command_name "SimpleCov #{rand(1000000)}"
    coverage_dir File.join(ENV['REPORT_ROOT'] || __dir__, 'coverage')
    merge_timeout 7200 # Set largest gap between resultsets of 30 minutes
    # any custom configs like groups and filters can be here at a central place
    enable_coverage :branch
    primary_coverage :branch
    print_error_status=true
  end
end



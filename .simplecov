SimpleCov.start 'rails' do
  coverage_dir File.join(ENV['REPORT_ROOT'] || __dir__, 'coverage')
  # any custom configs like groups and filters can be here at a central place
end


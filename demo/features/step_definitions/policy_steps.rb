Given(/^a policy:$/) do |policy|
  policy_filename = "/run/possum/policy/#{@scenario_name.gsub(/[^a-zA-Z0-9\-_]+/, '_')}.yml"
  
  puts "Loading #{policy_filename}"
  
  require 'fileutils'
  
  FileUtils.rm_rf "/run/possum/policy/finished"
  File.write policy_filename, policy
  File.write "/run/possum/policy/load", policy_filename
  10.times do
    break if File.exists?("/run/possum/policy/finished")
    sleep 1
  end
  raise "Policy file failed to load" unless File.exists?("/run/possum/policy/finished")
end

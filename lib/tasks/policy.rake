namespace :policy do
  desc "Watch a file and reload the policy when it changes"
  task :watch, [ "file-name" ] do |t,args|
    require 'listen'
    require 'pathname'

    file_name = args["file-name"] or raise "file-name argument is required"
    dir_name = File.dirname file_name
    raise "Directory #{dir_name} does not exist" unless File.directory?(dir_name) 
    
    $stderr.puts "Watching directory '#{dir_name}' for changes to file '#{file_name}'"

    # Use polling because the efficient way doesn't work with Docker volume-mounted directories
    listener = Listen.to(dir_name, force_polling: true) do |modified, added, removed|
      (Array(added) + Array(modified)).each do |fname|
        # Only watch the designated file
        next unless fname == file_name
        policy_file_name = File.read(fname).strip
        do_load = begin
          File.unlink(fname)
          true
        rescue Errno::ENOENT
          false
        end
        if do_load
          $stderr.puts "Loading #{policy_file_name}"
          system *[ "rake", %Q(policy:load[#{policy_file_name}]) ]
        end
      end
    end
    listener.start
    while true
      sleep 1
    end
  end

  desc "Load policy data from a file"
  task :load, [ "file-name" ] => [ "environment" ] do |t,args|
    require 'loader'
    if ENV['DEBUG']
      Loader.enable_logging
    end
    
    file_name = args["file-name"] or raise "file-name argument is required"
  
    Loader.load file_name
  end
end

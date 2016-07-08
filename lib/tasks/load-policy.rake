namespace :policy do
  desc "Watch a file and reload the policy when it changes"
  task :watch, [ "file-name" ] do |t,args|
    require 'listen'
    file_name = args["file-name"] or raise "file-name argument is required"

    # Use polling because the efficient way doesn't work with Docker volume-mounted directories
    listener = Listen.to(file_name, force_polling: true) do |modified, added, removed|
      (Array(added) + Array(modified)).each do |fname|
        # Don't trigger on the policy files themselves
        next if fname =~ /.yml$/ || fname =~ /.yaml$/
        policy_file_name = File.read(fname).strip
        File.unlink(fname)
        $stderr.puts "Loading #{policy_file_name}"
        system *[ "rake", %Q(policy:load[#{policy_file_name}]) ]
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

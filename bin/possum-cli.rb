require 'gli'

include GLI::App

program_desc "Command and control application for Possum"

version File.read(File.expand_path("../VERSION", File.dirname(__FILE__)))

desc 'Run the application server'
command :server do |c|
  c.desc 'Policy file to load into the server'
  c.arg_name 'file_name'
  c.flag [ :f, :file ]

  c.desc 'Server listen port'
  c.arg_name 'port'
  c.default_value ENV['PORT'] || '80'
  c.flag [ :p, :port ]

  c.desc 'Server bind address'
  c.default_value ENV['BIND_ADDRESS'] || '0.0.0.0'
  c.arg_name 'address'
  c.flag [ :b, :'bind-address' ]
  
  c.action do |global_options,options,args|
    raise "No command arguments are allowed" unless args.empty?

    system "rake db:migrate" or exit $?.exitstatus
    
    if file_name = options[:file]
      system "rake policy:load[#{file_name}]" or exit $?.exitstatus
    end
    
    exec "rackup -p #{options[:port]} -o #{options[:'bind-address']}"
  end
end

desc "Watch a file and reload the policy if it's modified"
long_desc <<-DESC
To trigger a reload of the policy, replace the contents of the watched file with the path to 
the policy. Of course, the path must be visible to the container which is running "possum watch".
This can be a separate container from the application server. Both the application server and the
policy watcher should share the same backing database.
DESC
arg_name 'file_name'
command :watch do |c|
  c.action do |global_options,options,args|
    file_name = args.shift or raise "Expecting file_name argument"
    raise "No additional command arguments are allowed" unless args.empty?

    exec "rake policy:watch[#{file_name}]"
  end
end

exit run(ARGV)

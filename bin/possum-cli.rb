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
    exit_now! "No command arguments are allowed" unless args.empty?

    system "rake db:migrate" or exit $?.exitstatus
    
    if file_name = options[:file]
      system "rake policy:load[#{file_name}]" or exit $?.exitstatus
    end
    
    exec "rackup -p #{options[:port]} -o #{options[:'bind-address']}"
  end
end

desc "Manage the policy"
command :policy do |cgrp|
  cgrp.desc "Load the policy from a file"
  cgrp.arg_name "file_name"
  cgrp.command :load do |c|
    c.action do |global_options,options,args|
      file_name = args.shift or exit_now! "Expecting file_name argument"
      exit_now! "No additional command arguments are allowed" unless args.empty?
  
      exec "rake policy:load[#{file_name}]"
    end
  end
  
  cgrp.desc "Watch a file and reload the policy if it's modified"
  cgrp.long_desc <<-DESC
To trigger a reload of the policy, replace the contents of the watched file with the path to 
the policy. Of course, the path must be visible to the container which is running "possum watch".
This can be a separate container from the application server. Both the application server and the
policy watcher should share the same backing database.


Example:


$ docker run -d possum watch /run/possum/policy/load)"
  DESC
  cgrp.arg_name 'file_name'
  cgrp.command :watch do |c|
    c.action do |global_options,options,args|
      file_name = args.shift or exit_now! "Expecting file_name argument"
      exit_now! "No additional command arguments are allowed" unless args.empty?
  
      exec "rake policy:watch[#{file_name}]"
    end
  end
end

desc "Manage the data encryption key"
command :"data-key" do |cgrp|
  cgrp.desc "Generate a data encryption key"
  cgrp.long_desc <<-DESC
Use this command to generate a new Base64-encoded 256 bit data encrytion key.
Once generated, this key should be placed into the environment of the Possum 
server. It will be used to encrypt all sensitive data which is stored in the 
database, including the token-signing private key.


Example:


$ export POSSUM_DATA_KEY="$(docker run --rm possum data-key generate)"
  DESC
  cgrp.command :generate do |c|
    c.action do |global_options,options,args|
      exit_now! "No command arguments are allowed" unless args.empty?
    
      exec "rake generate-data-key"
    end
  end
end

desc "Manage the token-signing key"
command :"token-key" do |cgrp|
  cgrp.desc "Generate and save the token signing key"
  cgrp.long_desc <<-DESC
Use this command to generate and store a new 2048-bit RSA private key, used to 
sign auth tokens. The POSSUM_DATA_KEY must be available in the environment
when this command is called, since it's used to encrypt the token-signing key
in the database.


Example:


$ docker run --rm possum token-key generate
  DESC
  cgrp.command :generate do |c|
    c.action do |global_options,options,args|
      exit_now! "No command arguments are allowed" unless args.empty?
      
      require 'sequel'
      require 'slosilo'
      require 'slosilo/adapters/sequel_adapter'

      Sequel::Model.db = Sequel.connect(ENV['DATABASE_URL'])
      
      if data_key = ENV['POSSUM_DATA_KEY']
        Slosilo::encryption_key = Base64.strict_decode64 data_key.strip
        Slosilo::adapter = Slosilo::Adapters::SequelAdapter.new
      else
        exit_now! "No POSSUM_DATA_KEY"
      end

      exit_now! "Token-signing key already exists" if Slosilo[:own]
      
      pkey = Slosilo::Key.new
      Slosilo[:own] = pkey
        
      $stderr.puts "Created and saved new token-signing key. Public key is:"
      puts pkey.to_s
    end
  end
end

desc "Manage the database"
command :db do |cgrp|
  cgrp.desc "Create and/or upgrade the database schema"
  cgrp.command :migrate do |c|
    c.action do |global_options,options,args|
      exit_now! "No command arguments are allowed" unless args.empty?
      
      exec "rake db:migrate"
    end
  end
end

exit run(ARGV)

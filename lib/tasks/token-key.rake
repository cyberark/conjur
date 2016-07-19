namespace :"token-key" do
  desc "Test whether the token-signing key already exists"
  task :exists => [ "environment" ] do
    puts !!Slosilo[:own]
  end

  desc "Create and store the token key"
  task :generate => [ "environment" ] do
    require 'slosilo'

    if Slosilo[:own]
      $stderr.puts "Token-signing key already exists"
      exit 0
    end
    
    pkey = Slosilo::Key.new
    Slosilo[:own] = pkey
      
    $stderr.puts "Created and saved new token-signing key. Public key is:"
    puts pkey.to_s
  end
end
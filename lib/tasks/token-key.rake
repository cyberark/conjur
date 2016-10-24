namespace :"token-key" do
  def signing_key_key account
    [ "authn", account ].join(":")
  end

  desc "Test whether the token-signing key already exists"
  task :exists, [ "account" ] => [ "environment" ] do |t,args|
    puts !!Slosilo[signing_key_key args[:account]]
  end

  desc "Create and store the token key"
  task :generate, [ "account" ] => [ "environment" ] do |t,args|
    require 'slosilo'

    account = args[:account].to_sym
    if Slosilo[signing_key_key account]
      $stderr.puts "Token-signing key already exists for account '#{account}'"
      exit 0
    end
    
    pkey = Slosilo::Key.new
    Slosilo[signing_key_key account] = pkey
      
    $stderr.puts "Created and saved new token-signing key for account '#{account}'. Public key is:"
    puts pkey.to_s
  end
end

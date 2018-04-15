namespace :"account" do
  def signing_key_key account
    [ "authn", account ].join(":")
  end

  desc "Test whether an account already exists"
  task :exists, [ "account" ] => [ "environment" ] do |t,args|
    puts !!Slosilo[signing_key_key args[:account]]
  end

  desc "Create an account"
  task :create, [ "account", "must_create" ] => [ "environment" ] do |t,args|
    Account.find_or_create_accounts_resource
    account_id = args[:account]
    begin
      Account.create args[:account]
      $stderr.puts "Created new account #{account_id.inspect}"
    rescue Exceptions::RecordExists
      $stderr.puts "Account #{account_id.inspect} already exists"
      if args[:must_create] == "true"
        exit 1
      end
    end
    account = Account.new account_id
    puts "Token-Signing Public Key: #{account.token_key.to_s}"
    puts "API key for admin: #{account.admin_role_api_key}"
end

  desc "Delete an account"
  task :delete, [ "account" ] => [ "environment" ] do |t,args|
    begin
      Account.new(args[:account]).delete
      $stderr.puts "Deleted account '#{args[:account]}'"
    rescue Sequel::NoMatchingRow
      $stderr.puts "Account '#{args[:account]}' not found"
      exit 1
    end
  end
end

# frozen_string_literal: true

namespace :"account" do

  desc "Test whether the token-signing key already exists"
  task :exists, [ "account" ] => [ "environment" ] do |t,args|
    puts !!Account.token_key(args[:account], "user") && !!Account.token_key(args[:account], "host")
  end

  desc "Create an account"
  task :create, [ "account" ] => [ "environment" ] do |t,args|
    Account.find_or_create_accounts_resource
    begin
      api_key = Account.create(args[:account])
      account = Account.new(args[:account])
      $stderr.puts("Created new account '#{account.id}'")
      puts("Hosts' Token-Signing Public Key:\n#{account.token_key("user").to_s}")
      puts("Users' Token-Signing Public Key:\n#{account.token_key("host").to_s}")
      puts("API key for admin: #{api_key}")
    rescue Exceptions::RecordExists
      $stderr.puts("Account '#{args[:account]}' already exists")
      exit(1)
    end
  end

  desc "Create an account with a preset password"
  task :create_with_password, [ "account", "password" ] => [ "environment" ] do |t,args|
    unless Conjur::Password.valid?(args[:password])
      $stderr.puts(::Errors::Conjur::InsufficientPasswordComplexity.new.to_s)
      exit 1
    end

    Account.find_or_create_accounts_resource
    begin
      Account.create(args[:account])
      account = Account.new(args[:account])
      $stderr.puts "Created new account '#{account.id}'"
      puts "Hosts' Token-Signing Public Key:\n#{account.token_key("user").to_s}"
      puts "Users' Token-Signing Public Key:\n#{account.token_key("host").to_s}"

      role_id = "#{args[:account]}:user:admin"
      Role[role_id].password = args[:password]
      puts "Password is set"
    rescue Exceptions::RecordExists
      $stderr.puts "Account '#{args[:account]}' already exists"
      exit 1
    end
  end

  desc "Delete an account"
  task :delete, [ "account" ] => [ "environment" ] do |t,args|
    begin
      Account.new(args[:account]).delete
      $stderr.puts("Deleted account '#{args[:account]}'")
    rescue Sequel::NoMatchingRow
      $stderr.puts("Account '#{args[:account]}' not found")
      exit(1)
    end
  end
end

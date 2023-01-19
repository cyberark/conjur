# frozen_string_literal: true

namespace :"account" do
  def signing_key_key account
    [ "authn", account ].join(":")
  end

  desc "Test whether the token-signing key already exists"
  task :exists, [ "account" ] => [ "environment" ] do |t,args|
    puts !!Slosilo[signing_key_key args[:account]]
  end

  desc "Create an account"
  task :create, [ "account" ] => [ "environment" ] do |t,args|
    Account.find_or_create_accounts_resource
    begin
      api_key = Account.create args[:account]
      account = Account.new args[:account]
      $stderr.puts "Created new account '#{account.id}'"
      puts "Token-Signing Public Key: #{account.token_key.to_s}"
      puts "API key for admin: #{api_key}"
    rescue Exceptions::RecordExists
      $stderr.puts "Account '#{args[:account]}' already exists"
      exit 1
    end
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

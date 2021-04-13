# frozen_string_literal: true

namespace :password do
  desc "Validate password strength"
  task :validate_strength, ["password"] => [ "environment" ] do |_, args|
    unless Conjur::Password.valid?(args[:password])
      $stderr.puts(::Errors::Conjur::InsufficientPasswordComplexity.new.to_s)
      exit 1
    end
    puts "Password strength validated successfully"
  end
end

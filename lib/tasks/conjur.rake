namespace :conjur do
  desc "Create an admin user (with a random password) and a database key"
  task init: ['db:migrate', :environment] do
    require 'random_password_generator'

    if AuthnUser.find login: 'admin'
      puts "User 'admin' already exists. Not creating."
    else
      password = RandomPasswordGenerator.generate
      AuthnUser.create login: 'admin', password: password
      puts "Created user 'admin' with password '#{password}'."
    end
    
    if ENV['POSSUM_SLOSILO_KEY']
      puts "POSSUM_SLOSILO_KEY environment variable already set - you're good to go."
    else
      key = Slosilo::Symmetric.new.random_key.encode64
      puts "Randomly generated POSSUM_SLOSILO_KEY=#{key}"
      puts "Make sure to put it in the server environment (or it will break)."
    end
  end
end

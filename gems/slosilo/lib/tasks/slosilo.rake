namespace :slosilo do
  desc "Dump a public key"
  task :dump, [:name] => :environment do |t, args|
    args.with_defaults(:name => :own)
    puts Slosilo[args[:name]]
  end
  
  desc "Enroll a key"
  task :enroll, [:name] => :environment do |t, args|
    key = Slosilo::Key.new STDIN.read
    Slosilo[args[:name]] = key
    puts key
  end

  desc "Generate a key pair"
  task :generate, [:name] => :environment do |t, args|
    args.with_defaults(:name => :own)
    key = Slosilo::Key.new
    Slosilo[args[:name]] = key
    puts key
  end

  desc "Migrate to a new database schema"
  task :migrate => :environment do |t|
    Slosilo.adapter.migrate!
  end

  desc "Recalculate fingerprints in keystore"
  task :recalculate_fingerprints => :environment do |t|
    Slosilo.adapter.recalculate_fingerprints
  end
end

namespace :railties do
  namespace :install do
    task migrations: :environment do
      Dir["#{__dir__}/../../db/migrate/*.rb"].each do |file|
        filename = file.split('/').last
        timestampless_name = filename.match(/\d+_(.+)/)[1]
        FileUtils.cp(file, "db/migrate/#{Time.now.strftime('%Y%m%d%H%M%S')}_#{timestampless_name}")
      end
    end
  end
end

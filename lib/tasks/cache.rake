namespace :cache do
  desc "Clearing Rails cache"
  task clear: [ "environment" ] do
    Rails.cache.clear
  end
end

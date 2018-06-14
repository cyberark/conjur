require 'aruba'
require 'aruba/cucumber'

# Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://possum'
# Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'

module RotatorWorld

  def pg_host
    'testdb'
  end

  def run_sql_in_testdb(sql, user='postgres')
    system("psql -h #{pg_host} -U #{user} -c \"#{sql}\"")
  end
end

World(RotatorWorld)

module RotatorWorld

  def pg_host
    'testdb'
  end

  def pg_login_result(user, pw)
    system("PGPASSWORD=#{pw} psql -c \"\\q\" -h #{pg_host} -U #{user}")
  end

  def run_sql_in_testdb(sql, user='postgres', pw='postgres_secret')
    system("PGPASSWORD=#{pw} psql -h #{pg_host} -U #{user} -c \"#{sql}\"")
  end

  def variable_resource(var)
    conjur_api.resource("cucumber:variable:#{var}")
  end
end

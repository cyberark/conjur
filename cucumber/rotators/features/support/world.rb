module RotatorWorld
  def pg_host
    'testdb'
  end

  def run_sql_in_testdb(sql, user='postgres', pw='postgres_secret')
    system("PGPASSWORD=#{pw} psql -h #{pg_host} -U #{user} -c \"#{sql}\"")
  end
end

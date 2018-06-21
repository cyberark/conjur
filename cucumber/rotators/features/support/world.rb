module RotatorWorld

  # stores history of all rotated passwords
  #
  attr_reader :db_passwords, :conjur_passwords

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

  #
  # Polling / Watching for changes
  #

  def start_polling_for_changes(var_id, db_user)
    @conjur_passwords = []
    @db_passwords = []
    @keep_polling = true

    Thread.new do
      while @keep_polling do

        # NOTE: We rescue here because we don't want errors in these lines
        #       to kill the entire threads.  It's perfectly valid to attempt
        #       to read the variables or access the db when we cannot.
        #
        pw = variable_resource(var_id)&.value rescue nil
        pw_works_in_db = pg_login_result(db_user, pw) if pw rescue nil

        # we only record it if they're synced -- avoids race conditions
        if pw_works_in_db
          add_conjur_password(pw) if new_conjur_pw?(pw)
          add_db_password(pw) if new_db_pw?(pw)
        end
        sleep(0.3)
      end
    end
  end

  def stop_polling_for_changes
    @keep_polling = false
  end

  private

  def add_db_password(pw)
    @db_passwords = (@db_passwords || []) << pw
  end

  def add_conjur_password(pw)
    @conjur_passwords = (@conjur_passwords || []) << pw
  end

  def new_conjur_pw?(pw)
    pw != @conjur_passwords.last
  end

  def new_db_pw?(pw)
    pw != @db_passwords.last
  end


end

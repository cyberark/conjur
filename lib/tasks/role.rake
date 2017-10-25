namespace :role do
  desc "Retrieve the API key for the given role"
  task :"retrieve-key", [:role_id] => [:environment] do |t, args|
    begin
      creds = Credentials.first!(role_id: args[:role_id])
      puts creds.api_key
    rescue Sequel::NoMatchingRow
      $stderr.puts "error: #{args[:role_id]} is not a role"
      puts
      exit 1
    end
  end
end

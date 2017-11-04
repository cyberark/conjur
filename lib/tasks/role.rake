namespace :role do
  desc "Retrieve the API key for the given role"
  task :"retrieve-key", [:role_id] => [:environment] do |t, args|
    begin
      role = Role.first!(role_id: args[:role_id])
      puts role.api_key
    rescue Sequel::NoMatchingRow
      # If no such role exists, print an error to stderr and a blank line to
      # stdout so that you always get one line of output per role.
      $stderr.puts "error: role does not exist: #{args[:role_id]}"
      puts
      exit 1
    end
  end
end

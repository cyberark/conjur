namespace :"role" do
  desc "Retrieve the API key for the given role"
  task :"retrieve-key", [:role_id] => [:environment] do |t, args|
    begin
      creds = Credentials.first!(role_id: args[:role_id])
      $stderr.puts creds.api_key
    rescue Sequel::NoMatchingRow
      $stderr.puts "Role '#{args[:role_id]}' not found"
      exit 1
    end
  end
end

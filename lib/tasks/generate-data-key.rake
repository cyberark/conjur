desc "Create a data encryption key, which should be placed in the environment as POSSUM_DATA_KEY"
task :"generate-data-key" do
  require 'slosilo'
  require 'base64'
  key = Base64.strict_encode64(Slosilo::Symmetric.new.random_key)
  puts "POSSUM_DATA_KEY=\"#{key}\""
  $stderr.puts "Make sure to put it in the server environment (or it will break)."
end

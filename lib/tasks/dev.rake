# Load development tasks. 
# Assume any LoadErrors to be caused by the production environment missing
# required gems, and skip this file.

Dir[Rails.root.join("lib/tasks/dev/**/*.rb")].each do |f| 
  begin
    require f
  rescue LoadError
    $stderr.puts "LoadError requiring rake task file #{f}: #{$!}"
  end
end

# frozen_string_literal: true

# Load development tasks. 
# Assume any LoadErrors to be caused by the production environment missing
# required gems, and skip this file.

Dir[Rails.root.join("lib/tasks/dev/**/*.rb")].sort.each do |f| 
  begin
    require f
  rescue LoadError
    # "docker run" mixes stderr with stdout, polluting command output.
    # $stderr.puts "LoadError requiring rake task file #{f}: #{$!}"
  end
end

# frozen_string_literal: true

module Error
  # helps get information regarding current error codes.
  class ConjurCode
    def initialize(path)
      @path = path
      validate
    end

    def print_next_available
      id = next_code_id
      unless id
        $stderr.puts "The path doesn't contain any files with Conjur error codes"
        return
      end
      puts format("The next available error number is %d ( CONJ%05dE )", id, id)
    end

    # separate data-gathering from printing
    def next_code_id
      max_code = existing_codes.max
      max_code ? max_code + 1 : nil
    end

    def existing_codes
      codes = File.foreach(@path).map do |line|
        match = /code: \"CONJ(?<num>[0-9]+)E\"/.match(line)
        match ? match[:num].to_i : nil
      end
      codes.compact
    end

    def validate
      return if File.file?(@path)
      raise format("The following path:%s was not found", @path)
    end
  end
end

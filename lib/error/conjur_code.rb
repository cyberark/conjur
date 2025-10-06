# frozen_string_literal: true

require 'logger'

module Error
  # helps get information regarding current error codes.
  class ConjurCode
    def initialize(
      *paths,
      # Injected dependencies
      logger: Logger.new($stdout),
      output: $stdout
    )
      @logger = logger
      @output = output

      @paths = valid_paths(paths)
    end

    def print_next_available
      id = next_code_id

      unless id
        @logger.error(
          "The path doesn't contain any files with Conjur error codes"
        )
        return
      end

      @output.puts(
        format("The next available error number is %d ( CONJ%05d )", id, id)
      )

      id
    end

    # separate data-gathering from printing
    def next_code_id
      max_code = existing_codes.max
      max_code ? max_code + 1 : nil
    end

    # This is reported as :reek:NestedIterators, but splitting this apart
    # does not make it more readable.
    def existing_codes
      # For each file given
      @paths.map do |path|
        # Convert the lines into codes, if present
        File.foreach(path).map do |line|
          match = /code: "CONJ(?<num>[0-9]+)[DIWE]"/.match(line)
          match ? match[:num].to_i : nil
        end.compact
      end.flatten
    end

    def valid_paths(paths)
      paths.select do |path|
        next true if File.file?(path)

        @logger.warn("The following path was not found: #{path}")
        false
      end
    end
  end
end

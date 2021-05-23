# frozen_string_literal: true

require 'command_class'

module Commands
  Wait ||= CommandClass.new(
    dependencies: {
    },

    inputs: %i[
      retries
      port
    ]
  ) do
    def call
      $stdout.puts("Waiting for Conjur to be ready...")

      @retries.times do
        break if conjur_ready?

        $stdout.print(".")
        sleep(1)
      end

      if conjur_ready?
        $stdout.puts(" Conjur is ready!")
      else
        exit_now!(" Conjur is not ready after #{@retries} seconds") 
      end
    end

    private

    def conjur_ready?
      uri = URI.parse("http://localhost:#{@port}")
      begin
        response = Net::HTTP.get_response(uri)
        response.code.to_i < 300
      rescue
        false
      end
    end
  end
end

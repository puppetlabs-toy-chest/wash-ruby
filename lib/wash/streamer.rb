# frozen_string_literal: true

module Wash
  # Streamer is a class meant to be used by implementations of Wash::Entry#stream.
  class Streamer
    def initialize
      @first_chunk = true
    end

    # write writes the given chunk to STDOUT then flushes it to ensure that Wash
    # receives the data. If the chunk is the first chunk that's written, then
    # write will print the "200" header prior to writing the chunk.
    #
    # @param chunk The chunk to be written
    def write(chunk)
        if @first_chunk
          puts("200")
          @first_chunk = false
        end
        $stdout.print(chunk)
        $stdout.flush
    end
  end
end

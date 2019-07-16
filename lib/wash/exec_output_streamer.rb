# frozen_string_literal: true

module Wash
  # Exec is a class meant to be used by implementations of Wash::Entry#exec.
  class ExecOutputStreamer
    # write_stdout writes the given chunk to STDOUT then flushes it to ensure
    # that Wash receives the data.
    #
    # @param chunk The chunk to be written
    def write_stdout(chunk)
      STDOUT.print(chunk)
      STDOUT.flush
    end

    # write_stderr writes the given chunk to STDERR then flushes it to ensure
    # that Wash receives the data.
    def write_stderr(chunk)
      STDERR.print(chunk)
      STDERR.flush
    end
  end
end


# frozen_string_literal: true
require "monoliza/async_runner"

# Public interface to the AsyncRunner. AsyncRunner runs in the background,
# and Client communicates with it.
module Monoliza
  class AsyncRunner
    class RactorClient
      def self.start_server(spec)
        cmd_port = Ractor::Port.new
        read_io, write_io = IO.pipe
        r = AsyncRunner.new(spec:, cmd_port:, wakeup_io: read_io)
        yield r if block_given?
        runner = Ractor.new(r) {|r| r.run }
        new runner:, cmd_port:, wakeup_io: write_io
      end

      def initialize(runner:, cmd_port:, wakeup_io:)
        @runner, @cmd_port, @wakeup_io = runner, cmd_port, wakeup_io
      end

      def <<(cmd)
        @runner << cmd
        @wakeup_io.putc AsyncRunner::WAKEUP_BYTE
        @cmd_port.receive
      rescue Errno::EPIPE
        raise "Failed to write to @runner's pipe"
      end
    end
  end
end

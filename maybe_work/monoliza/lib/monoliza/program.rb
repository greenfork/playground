# frozen_string_literal: true

require "open3"

# An executable program with common lifecycle methods. It is expected to
# print something to standard output and standard error, and this is
# captured for output by the Runner.
module Monoliza
  class Program
    attr_reader :id

    def initialize(id:, cmd:, stdin:, stdout:, stderr:, thread:)
      @id, @cmd, @stdin, @stdout, @stderr, @thread = id, cmd, stdin, stdout, stderr, thread
      @stdin.close
      @stdout_ready = @stderr_ready = false
      @stopping = false
    end

    def self.start_from_spec(spec)
      stdin, stdout, stderr, thread = Open3.popen3(spec.cmd)
      new(id: spec.id, cmd: spec.cmd, stdin:, stdout:, stderr:, thread:)
    rescue Errno::ENOENT
      # From Procfile, we get all commands wrapped into `sh` so this error
      # could only happen when `sh` is not found on the system. Could happen
      # more often for other formats.
      raise "Unknown command: #{spec.cmd}"
    end

    def alive? = !dead?
    def dead? = !@thread.alive?
    def stopping? = @stopping

    def read_stdout
      if @stdout_ready
        @stdout_ready = false
        out = @stdout.gets
      end
    end

    def read_stderr
      if @stderr_ready
        @stderr_ready = false
        @stderr.gets
      end
    end

    def ios = [@stdout, @stderr]

    def mark_ready(io)
      if io == @stdout
        @stdout_ready = true
      elsif io == @stderr
        @stderr_ready = true
      end
    end

    def stop
      if alive? && !@stopping
        @stopping = true
        @stdout.flush
        @stderr.flush
        Process.kill "SIGTERM", @thread.pid
        @stopping = false
      end
    rescue Errno::ESRCH, Errno::EPERM
    end
  end
end

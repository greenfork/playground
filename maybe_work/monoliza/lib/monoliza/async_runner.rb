# frozen_string_literal: true

require "monoliza/runner/writing"
require "monoliza/async_runner/commandable"

# Client-Server architectured Runner of multiple programs.
module Monoliza
  class AsyncRunner
    include Runner::Writing, Commandable

    WAKEUP_BYTE = 1

    def initialize(spec:, cmd_port:, wakeup_io:)
      @spec = spec
      @running_programs = []
      @started_programs = []
      @watch_ios = []
      @cmd_port, @wakeup_io = cmd_port, wakeup_io
      @is_pending_cmd = false
      @should_stop = false
      init_writer
    end

    def run
      until @should_stop
        if ready_io = check_ready_io
          remove_wakeup_io(ready_io[0])
          programs = ready_programs(ready_io[0])
          write_programs_output(programs)
          process_cmd
        end
        prune_dead_programs
      end
    end

    private
      def check_ready_io
        ios_to_watch = @running_programs.flat_map(&:ios)
        ios_to_watch << @wakeup_io
        IO.select(ios_to_watch)
      end

      def ready_programs(ios)
        programs = ios.map{|io| @running_programs.find{ it.mark_ready(io) } }
        programs.uniq!(&:id)
        programs
      end

      def prune_dead_programs
        @running_programs.filter! do |program|
          next true if program.alive?
          program.stop
          false
        end
      end
  end
end

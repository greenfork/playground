# frozen_string_literal: true

require "monoliza/runner/signals"
require "monoliza/runner/controllable"
require "monoliza/runner/writing"

# Run several programs and print their output, typically to the console.
module Monoliza
  class Runner
    include Controllable, Signals, Writing

    EMPTY_ARRAY = [].freeze

    def initialize(spec)
      @spec = spec
      @running_programs = []
      init_writer
    end

    def run
      trap_signals
      start_all

      until @running_programs.empty?
        ready_programs = select_ready_programs
        write_programs_output(ready_programs)
        prune_dead_programs
        sleep 0.01
      end
    end

    private
      def select_ready_programs
        ready = IO.select(@running_programs.flat_map(&:ios), nil, nil, 1)
        ready ? programs_from_ios(ready[0]) : EMPTY_ARRAY
      end

      def programs_from_ios(ios)
        programs = ios.map{|io| @running_programs.find{ it.mark_ready(io) } }
        programs.compact!
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

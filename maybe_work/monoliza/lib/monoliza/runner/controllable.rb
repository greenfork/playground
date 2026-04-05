# frozen_string_literal: true

require "monoliza/program"

# Controls the programs in the spec: start, stop, restart, etc.
module Monoliza
  class Runner
    module Controllable
      def start(id)
        unless @running_programs.find{ it.id == id }
          program = Program.start_from_spec(@spec[id])
          @running_programs << program
          add_to_started_programs program
          id
        end
      end

      def start_all
        @spec.filter_map{|id, _| start(id) }
      end

      def stop(id)
        if program = @running_programs.find{ it.id == id }
          @running_programs.reject!{ it.id == id }
          program.stop
          id
        end
      end

      def stop_all
        @running_programs.filter_map{ stop(it.id) }
      end

      def restart(id)
        stop(id) && start(id)
      end

      private
        def add_to_started_programs(program)
          return unless defined?(@started_programs)

          @started_programs.delete_if{ it.id == program.id } << program
        end
    end
  end
end

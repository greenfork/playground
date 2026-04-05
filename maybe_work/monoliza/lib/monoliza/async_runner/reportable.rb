# frozen_string_literal: true

# Provides a "state" of the runner together with possible actions.
module Monoliza
  class AsyncRunner
    module Reportable
      Report = Data.define(:items, :allowed_actions)
      ReportItem = Data.define(:id, :cmd, :state, :allowed_actions)

      def report
        items =
          @spec.keys.sort.map do |id|
            program_spec = @spec[id]
            program = @started_programs.find{ it.id == id }
            state = program_state(program)
            ReportItem.new id:, cmd: program_spec.cmd, state:,
              allowed_actions: allowed_program_actions(state)
          end

        Report.new items:, allowed_actions: allowed_runner_actions(items)
      end

      private
        def program_state(program)
          if program.nil? then :not_started
          elsif program.alive? then :alive
          elsif program.dead? then :dead
          elsif program.stopping? then :stopping
          else :unknown
          end
        end

        NOT_STARTED_ACTIONS = %i[start].freeze
        ALIVE_ACTIONS = %i[stop restart].freeze
        DEAD_ACTIONS = %i[start].freeze
        STOPPING_ACTIONS = [].freeze
        UNKNOWN_ACTIONS = [].freeze
        private_constant :NOT_STARTED_ACTIONS, :ALIVE_ACTIONS, :DEAD_ACTIONS,
          :STOPPING_ACTIONS, :UNKNOWN_ACTIONS

        def allowed_program_actions(state)
          case state
          when :not_started then NOT_STARTED_ACTIONS
          when :alive then ALIVE_ACTIONS
          when :dead then DEAD_ACTIONS
          when :stopping then STOPPING_ACTIONS
          when :unknown then UNKNOWN_ACTIONS
          else raise "Unreachable"
          end
        end

        def allowed_runner_actions(items)
          allowed_actions = []
          allowed_actions << :start_all if items.any?{ it.allowed_actions.include?(:start) }
          allowed_actions << :stop_all if items.any?{ it.allowed_actions.include?(:stop) }
          allowed_actions
        end
    end
  end
end

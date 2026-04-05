# frozen_string_literal: true

require "monoliza/runner/controllable"
require "monoliza/async_runner/reportable"

# Allow receiving commands through a Ractor and do corresponding actions.
module Monoliza
  class AsyncRunner
    module Commandable
      include Runner::Controllable, Reportable

      private
        def remove_wakeup_io(ios)
          if ios.reject!{ it == @wakeup_io }
            byte = @wakeup_io.readbyte
            raise "Unexpected byte: #{byte}" unless byte == WAKEUP_BYTE
            @is_pending_cmd = true
          end
        end

        def process_cmd
          return unless @is_pending_cmd
          @is_pending_cmd = false

          response =
            case Ractor.receive
            in :start_all then start_all
            in :stop_all then stop_all
            in [:start, id] then start(id)
            in [:stop, id] then stop(id)
            in [:restart, id] then restart(id)
            in :report then report
            in :shutdown
              $stderr.puts "Runner shutting down..."
              stop_all
              @should_stop = true
            else
              :unknown
            end

          @cmd_port << response
        end
    end
  end
end

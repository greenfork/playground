# frozen_string_literal: true

# Handle operating system signals for clean shutdown, etc.
module Monoliza
  class Runner
    module Signals
      private

      def trap_signals
        Signal.trap("SIGINT") { handle_sigint }
        Signal.trap("SIGTERM") { handle_sigterm }
      end

      def handle_sigint
        $stderr.puts "SIGINT: Shutting down..."
        stop_all
      end

      def handle_sigterm
        $stderr.puts "SIGTERM: Shutting down..."
        stop_all
      end
    end
  end
end

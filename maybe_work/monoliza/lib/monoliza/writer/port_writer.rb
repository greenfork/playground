# frozen_string_literal: true

# Writes a structured message to a port or queue.
module Monoliza
  class Writer
    class PortWriter
      def initialize(port)
        @port = port
      end

      def write(id:, message:, is_error:)
        @port << [id, message, is_error]
      end
    end
  end
end

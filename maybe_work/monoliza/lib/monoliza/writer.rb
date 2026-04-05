# frozen_string_literal: true

require "monoliza/writer/console_writer"
require "monoliza/writer/port_writer"

# Container for different concrete writers. Delegates writing to all
# the @writers.
module Monoliza
  class Writer
    def initialize
      @writers = []
    end

    def add_console_writer
      @writers << ConsoleWriter.new
    end

    def add_port_writer(port)
      @writers << PortWriter.new(port)
    end

    def write(id:, message:, is_error: false)
      @writers.each{ it.write(id:, message:, is_error:) }
    end
  end
end

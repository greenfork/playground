# frozen_string_literal: true

require "monoliza/writer"

# Use the Writer class.
module Monoliza
  class Runner
    module Writing
      attr_reader :writer

      private
        def init_writer
          @writer = Writer.new
        end

        def write_programs_output(programs)
          programs.each do |program|
            if out = program.read_stdout
              @writer.write id: program.id, message: out
            end

            if err = program.read_stderr
              @writer.write id: program.id, message: err, is_error: true
            end
          end
        end
    end
  end
end

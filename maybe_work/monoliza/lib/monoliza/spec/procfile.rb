# frozen_string_literal: true

require "monoliza/spec/program_spec"

# Parses Procfile.
module Monoliza
  class Spec
    class Procfile
      class InvalidFormat < StandardError; end
    
      class << self
        def parse_from_file(path)
          pathname = Pathname.new(path)
          raise ArgumentError, "No Procfile found at path '#{path}'" unless pathname.exist?

          parsed = []

          pathname.each_line do |line|
            next if line.start_with? "#"
            id, cmd = line.split(":", 2)
            raise InvalidFormat, "Line has invalid format: '#{line}'" if cmd.nil?
            parsed << ProgramSpec.new(id:, cmd: parse_cmd(cmd))
          end

          parsed
        end

        private
          def parse_cmd(cmd)
            envs, cmd_parts = cmd.split.partition{ it.include?("=") }
            final_cmd = String.new

            if !envs.empty?
              final_cmd << "env "
              envs.each do |env|
                final_cmd << env
              end
              final_cmd << " "
            end

            final_cmd << "sh -c '" << cmd_parts.join(" ") << "'"
          end
      end
    end
  end
end

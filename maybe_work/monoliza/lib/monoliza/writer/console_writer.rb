# frozen_string_literal: true

# Writes possibly colored output to the console. Respencts the NO_COLOR
# environment variable.
module Monoliza
  class Writer
    class ConsoleWriter
      ANSI = {
        reset: 0, black: 30, red: 31, green: 32, yellow: 33, blue: 34,
        magenta: 35, cyan: 36, white: 37, bright_black: 30, bright_red: 31,
        bright_green: 32, bright_yellow: 33, bright_blue: 34,
        bright_magenta: 35, bright_cyan: 36, bright_white: 37 }.freeze

      COLORS = %i[
        cyan yellow green magenta blue bright_cyan bright_yellow
        bright_green bright_magenta bright_red bright_blue].freeze

      ANSI_RESET = "\e[0m"
      ANSI_ERROR = "\e[31m"

      def initialize
        @colors = {}
      end

      def write(id:, message:, is_error:)
        log_line = String.new
        if is_error
          log_line << colored{ANSI_ERROR} << "STDERR "
        else
          log_line << colored{ansi_color(id)}
        end
        log_line << id << ": " << colored{ANSI_RESET} << message
        $stdout.write log_line
        $stdout.flush
      end

      private
        def ansi_color(id)
          @colors[id] ||=
            begin
              color = COLORS[@colors.size % COLORS.size]
              ansi = ANSI[color]
              "\e[#{ansi}m"
            end
        end

        def colored
          no_color? ? "" : yield
        end

        def no_color?
          return @no_color if defined?(@no_color)
          return @no_color = true unless $stdout.isatty 
          no_color_env = ENV["NO_COLOR"]
          return @no_color = true if no_color_env && !no_color_env.empty?
          @no_color = false
        end
    end
  end
end

# frozen_string_literal: true

require "pcelka/server/writing"
require "pcelka/server/commandable"
require "pcelka/server/notifiable"

# Runs several command line programs.
module Pcelka
  class Server
    include Writing, Commandable, Notifiable

    WAKEUP_BYTE = 1

    # @param spec [Spec]
    # @param client_sink [Object#<<]
    # @param wakeup_io [IO#readbyte]
    # @param mailbox [Object#pop] receives messages
    # from clients.
    # @param programs_status_changed_cond
    # [Async::Condition]
    def initialize(spec:, client_sink:, wakeup_io:,
        mailbox:, programs_status_changed_cond:)
      @spec, @client_sink, @wakeup_io, @mailbox =
        spec, client_sink, wakeup_io, mailbox
      @running_programs = []
      @started_programs = []
      @watch_ios = []
      @is_pending_cmd = false
      @should_stop = false
      init_writer
      init_notifiable programs_status_changed_cond:
    end

    def run
      until @should_stop
        if ready_io = check_ready_io
          remove_wakeup_io(ready_io[0])
          programs = ready_programs(ready_io[0])
          write_programs_output(programs)
          process_cmd
        end
        notify_programs_status_changed
        prune_dead_programs
      end
    end

    private
      def check_ready_io
        ios_to_watch = @running_programs
          .flat_map(&:ios)
        ios_to_watch << @wakeup_io
        IO.select ios_to_watch, nil, nil, 0.1
      end

      def ready_programs(ios)
        programs = ios.map{|io| @running_programs
          .find{ it.mark_ready(io) } }
        programs.uniq!(&:id)
        programs
      end

      def prune_dead_programs
        @running_programs.filter! do |program|
          next true if program.alive?
          @writer.write app: program.id,
            message: "_died", is_error: true
          program.stop
          false
        end
      end
  end
end


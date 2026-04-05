# frozen_string_literal: true

require "monoliza/spec"
require "monoliza/runner"
require "monoliza/async_runner/ractor_client"

# Run and watch several programs at a time.
module Monoliza
  module_function

  def run_in_console_from_procfile(procfile)
    spec = Spec.from_procfile(procfile)
    runner = Runner.new(spec)
    runner.writer.add_console_writer
    runner.run
  end

  def run_async_from_procfile(procfile)
    spec = Spec.from_procfile(procfile)
    logs_port = Ractor::Port.new

    client = AsyncRunner::RactorClient.start_server(spec) do |r|
      r.writer.add_port_writer(logs_port)
    end
    client << :start_all

    Thread.new do
      while line = logs_port.receive
        puts "log: #{line.inspect}"
      end
    end

    p (client << :report)
    sleep 2
    client << :shutdown
  end
end

# frozen_string_literal: true
require_relative "db"

class RunnerClient
  def initialize(spec:)
    @spec = spec
    logs_port = Ractor::Port.new
    @logs_port = logs_port
    @runner_client = Monoliza::AsyncRunner::RactorClient.start_server(spec) do |r|
      r.writer.add_port_writer(logs_port)
    end
    @log_subscribers = []
    @log_subscribers_mutex = Mutex.new
    @server = nil
  end

  def <<(cmd)
    puts "RunnerClient sends #{cmd}"
    @runner_client << cmd
  end

  def async_receive_logs
    if @server&.alive?
      $stderr.puts "[#{__method__}] Runner server is already running"
      return
    end

    @server = Thread.new do
      while l = @logs_port.receive
        puts "Received from server: #{l}"
        last_id = DB[:logs].insert(app: l[0], log: l[1], is_error: l[2])

        @log_subscribers_mutex.synchronize do
          @log_subscribers.each{ it << last_id unless it.closed? }
        end
      end
    end
  end

  def log_subscribe(sub)
    @log_subscribers_mutex.synchronize do
      @log_subscribers << sub
    end
  end

  def log_unsubscribe(sub)
    @log_subscribers_mutex.synchronize do
      @log_subscribers.reject!{ it == sub }
    end
  end
end

RUNNER = RunnerClient.new(spec: Monoliza::Spec.from_procfile("Procfile"))
RUNNER.async_receive_logs

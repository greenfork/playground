# frozen_string_literal: true

dev = ENV["RACK_ENV"] == "development"

if dev
  require "logger"
  logger = Logger.new($stdout)
end

if Module.const_defined? :Falcon
  # https://github.com/socketry/falcon/issues/333
  class Falcon::Server
    alias_method :__original_accept, :accept

    def accept(...)
      __original_accept(...)
    rescue Errno::EPIPE, Errno::ECONNRESET
      # Client disconnected mid-response — expected.
    end
  end
end

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "rack/unreloader"
Unreloader = Rack::Unreloader.new(subclasses: %w'Roda Monoliza', logger: logger, reload: dev, autoload: dev){App}
require_relative "models"
Unreloader.require("lib/")
Unreloader.require("app.rb"){"App"}

require_relative "runner"
run(dev ? Unreloader : App.freeze.app)

unless dev
  Tilt.finalize!
  RubyVM::YJIT.enable if defined?(RubyVM::YJIT.enable)
end

freeze_core = !dev
if freeze_core
  begin
    require "refrigerator"
  rescue LoadError
  else
    require "nio" if defined?(Puma)
    Refrigerator.freeze_core
  end
end

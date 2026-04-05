# frozen_string_literal: true
require_relative "db"

if ENV["RACK_ENV"] == "development" || ENV["RACK_ENV"] == "test"
  require "logger"
  LOGGER = Logger.new($stdout)
  LOGGER.level = Logger::FATAL if ENV["RACK_ENV"] == "test"
  DB.loggers << LOGGER
end

require "sequel/core"
Sequel.extension :migration
Sequel::Migrator.run(DB, "db/migrations")

Sequel.extension :fiber_concurrency

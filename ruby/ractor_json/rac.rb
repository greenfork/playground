# frozen_string_literal: true
require 'json'

DOCUMENT = <<~JSON.freeze
  {"a": 1, "b": 2, "c": 3, "d": 4}
JSON

ractors = 5.times.map do
  Ractor.new do
    1_000_000.times do
      JSON.parse(DOCUMENT)
    end
  end
end
ractors.each(&:value)

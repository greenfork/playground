# frozen_string_literal: true
require 'json'

document = <<~JSON
  {"a": 1, "b": 2, "c": 3, "d": 4}
JSON

5_000_000.times do
  JSON.parse(document)
end

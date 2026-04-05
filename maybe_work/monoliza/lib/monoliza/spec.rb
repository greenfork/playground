# frozen_string_literal: true

require "monoliza/spec/procfile"

# Public interface for different Spec providers.
module Monoliza
  class Spec
    def self.from_procfile(path)
      Procfile.parse_from_file(path).to_h{[it.id, it]}.freeze
    end
  end
end

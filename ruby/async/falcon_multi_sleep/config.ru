require "bundler/inline"
gemfile do
  gem "roda"
  gem "falcon"
  gem "console"
  gem "rack"
end

require "roda"
require "console"

class A
  def initialize(cond)
    @cond = cond
  end

  def wait = @cond.wait

  def signal_in_n_seconds(n)
    Thread.new do
      sleep n
      @cond.signal
    end
  end
end

class App < Roda
  a = A.new Async::Condition.new

  route do |r|
    r.root do
      Console.warn "GET /"
      a.signal_in_n_seconds 5
      a.wait
      Console.warn "GET / done waiting"
      "ok"
    end
  end
end

run App.freeze.app

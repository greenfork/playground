require "async"

cond = Async::Condition.new

class A
  def initialize(cond)
    @cond = cond
  end

  def wait(n)
    while value = @cond.wait
      Console.info "Signal incoming", value: value, n: n
    end
  end
end

a = A.new(cond)

Sync do
  Async do
    a.wait(1)
  end
  Async do
    a.wait(2)
  end
  Async do
    id = 0
    while true
      cond.signal id
      id += 1
      sleep 1
    end
  end
end

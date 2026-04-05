require "benchmark/ips"

D = Data.define(:id, :message, :bool)

IDS = (1..100)
MESSAGES = Enumerator.produce("a", &:succ)
BOOLS = [true, false, false, true, true, false, false].cycle

def data
  IDS.zip(MESSAGES, BOOLS).inject([]) do |acc, (id, message, bool)|
    acc << D.new(id:, message:, bool:)
  end
end

def array
  IDS.zip(MESSAGES, BOOLS).inject([]) do |acc, (id, message, bool)|
    acc << [id, message, bool]
  end
end

def array_alloc
  arr = Array.new(3)
  IDS.zip(MESSAGES, BOOLS).inject([]) do |acc, (id, message, bool)|
    arr[0] = id
    arr[1] = message
    arr[2] = bool
    acc << arr
  end
end

# def hash
#   IDS.zip(MESSAGES, BOOLS).inject([]) do |acc, (id, message, bool)|
#     acc << ({ id => [message, bool] })
#   end
# end

Benchmark.ips do |x|
  x.report("data") { data }
  x.report("array") { array }
  x.report("array_alloc") { array_alloc }
  # x.report("hash") { hash }
  x.compare!
end

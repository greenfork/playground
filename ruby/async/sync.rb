require "async"
require "benchmark/ips"

def sl = sleep 1

def sync
  Sync do |task|
    10.times do
      task.async do
        sl
      end
    end
  end
end

def async
  Async do |task|
    10.times do
      task.async do
        sl
      end
    end
  end
end

def async_async
  Async do |task|
    10.times do
      Async do
        sl
      end
    end
  end
end

def sync_async
  Sync do |task|
    10.times do
      Async do
        sl
      end
    end
  end
end

Benchmark.ips do |x|
  x.report("sync"){sync}
  x.report("async"){async}
  x.report("async_async"){async_async}
  x.report("sync_async"){sync_async}
  x.compare!
end

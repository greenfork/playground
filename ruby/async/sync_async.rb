require "async"

Sync do
  Sync do
    sleep 1
    puts "first slept"
  end

  Async do
    sleep 1
    puts "second slept"
  end
end

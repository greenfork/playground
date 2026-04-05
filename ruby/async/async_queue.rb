require "async"

q1 = Async::Queue.new
q2 = Async::Queue.new
q3 = Async::Queue.new

queues = [q1, q2, q3].freeze

sync = proc do
  Sync do |task|
    queues.each do |q|
      task.async do
        q.pop
        puts "received!"
      end
    end
  end
end

pure = proc do
  queues.each do |q|
    q.pop
    puts "received!"
  end
end

Sync do
  Async do
    queues.reverse.each do |q|
      sleep 1
      q << :bop
    end
  end

  # pure.call
  sync.call
end

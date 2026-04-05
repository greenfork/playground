require "async"

p1 = Ractor::Port.new
r1 = Ractor.new(p1) do |p|
  puts "a"
  Ractor.receive
  puts "b"
  sleep 1
  puts "c"
  p << :bop
end

p2 = Ractor::Port.new
r2 = Ractor.new(p2) do |p|
  puts "a"
  Ractor.receive
  puts "b"
  sleep 1
  puts "c"
  p << :bop
end

p3 = Ractor::Port.new
r3 = Ractor.new(p3) do |p|
  puts "a"
  Ractor.receive
  puts "b"
  sleep 1
  puts "c"
  p << :bop
end

ractors = [[r1, p1], [r2, p2], [r3, p3]].freeze

sync = proc do
  Sync do |task|
    ractors.each do |(r, p)|
      task.async do
        puts "1"
        r << :bup
        puts "2"
        p.receive
        puts "3"
      end
    end
  end
end

pure = proc do
  ractors.each do |(r, p)|
    r << :bup
    p.receive
  end
end

# pure.call
sync.call

# same, 3 seconds

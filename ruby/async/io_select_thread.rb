require "open3"

class Server
  def initialize(wakeup:, queue:)
    @wakeup, @queue = wakeup, queue
    @programs = [wakeup]
  end

  def add_program(str)
    _stdin, stdout_and_stderr, _wait_thread = Open3.popen2e(str)
    @programs << stdout_and_stderr
  end

  def run
    while true
      ready = IO.select @programs
      ios = ready[0]

      if ios.reject!{ it == @wakeup }
        @wakeup.read(1)
        puts @queue.pop
      end

      ios.each do |io|
        puts io.gets
      end
    end
  end
end

q = Queue.new
read, write = IO.pipe
s = Server.new(wakeup: read, queue: q)
s.add_program "sh -c 'while true; do echo 1; sleep 1; done'"
s.add_program "sh -c 'while true; do echo 2; sleep 1; done'"

Thread.new { s.run }

puts "start"
sleep 1
q << "Hello!"
write << 9
sleep 1
q << "World!"
write << 9
sleep 1
puts "end"

def server_sent_events?(env)
	env['HTTP_ACCEPT'].include?('text/event-stream')
end

class Falcon::Server
  alias_method :__original_accept, :accept

  def accept(...)
    __original_accept(...)
  rescue Errno::EPIPE, Errno::ECONNRESET
    # Client disconnected mid-response — expected.
  end
end

run do |env|
	if server_sent_events?(env)
		body = proc do |stream|
			while true
				stream << "data: The time is #{Time.now}\n\n"
				sleep 1
			end
		rescue => error
		ensure
			stream.close(error)
		end
		
		[200, {'content-type' => 'text/event-stream'}, body]
	else
		# Else the request is for the index page, return the contents of index.html:
		[200, {'content-type' => 'text/html'}, [File.read('index.html')]]
	end
end
